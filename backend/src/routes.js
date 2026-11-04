'use strict';
const crypto = require('node:crypto');
const { createAdminClient, createPublicClient } = require('./db');
const { HttpError, Validator, BLOOD_GROUPS, nowIn, ageOn } = require('./http');

const admin = createAdminClient();
const routes = [];
const route = (method, pattern, opts, handler) => {
  if (typeof opts === 'function') { handler = opts; opts = {}; }
  const keys = [];
  const re = new RegExp('^' + pattern.replace(/:([a-zA-Z]+)/g, (_, key) => (keys.push(key), '([^/]+)')) + '/?$');
  routes.push({ method, re, keys, handler, auth: opts.auth !== false, admin: !!opts.admin });
};

const SLOTS = ['08:00', '09:00', '10:00', '11:00', '13:00', '14:00', '15:00', '16:00'];

async function data(query) {
  const { data: value, error } = await query;
  if (error) {
    if (error.code === '23505') throw new HttpError(409, error.message);
    if (error.code === 'P0001') {
      const conflict = /already|full|no longer|only open/i.test(error.message);
      throw new HttpError(conflict ? 409 : 422, error.message);
    }
    throw error;
  }
  return value;
}

function authError(error, fallbackStatus = 400) {
  const message = error?.message || 'Authentication failed';
  if (/already registered|already been registered/i.test(message)) return new HttpError(409, 'That email is already registered');
  if (/invalid login credentials|invalid.*credentials/i.test(message)) return new HttpError(401, 'Incorrect email or password');
  if (/password/i.test(message) && /weak|short|least/i.test(message)) return new HttpError(422, message);
  return new HttpError(error?.status || fallbackStatus, message);
}

async function profileForAuthId(authUserId) {
  return data(admin.from('profiles').select('*').eq('user_id', authUserId).maybeSingle());
}

async function unreadCount(profileId) {
  const visible = await data(admin.from('notifications').select('id').or(`user_id.is.null,user_id.eq.${profileId}`));
  if (!visible.length) return 0;
  const reads = await data(admin.from('notification_reads').select('notification_id').eq('user_id', profileId));
  const readIds = new Set(reads.map((row) => row.notification_id));
  return visible.reduce((count, row) => count + (readIds.has(row.id) ? 0 : 1), 0);
}

async function userDto(profile) {
  const verification = await data(admin.from('donor_verifications').select('status')
    .eq('user_id', profile.id).order('id', { ascending: false }).limit(1).maybeSingle());
  return {
    id: Number(profile.id), fullName: profile.full_name, email: profile.email, phone: profile.phone,
    role: profile.role, isDonor: profile.is_donor,
    verificationStatus: verification?.status || 'none', unreadCount: await unreadCount(profile.id),
  };
}

function iso(value) { return value || null; }
const apptDto = (row) => ({
  id: row.id, fullName: row.full_name, phone: row.phone, date: row.preferred_date,
  time: String(row.preferred_time).slice(0, 5), status: row.status, note: row.note, createdAt: iso(row.created_at),
});
const bloodDto = (row) => ({
  id: row.id, patientName: row.patient_name, contactPerson: row.contact_person,
  contactNumber: row.contact_number, bloodGroup: row.blood_group, units: row.units,
  hospital: row.hospital, address: row.address, city: row.city, urgency: row.urgency,
  notes: row.notes, status: row.status, note: row.note, createdAt: iso(row.created_at),
});
const cardReqDto = (row) => ({
  id: row.id, cardCode: row.card_code, cardName: row.card_types?.name,
  fullName: row.full_name, birthDate: row.birth_date, mobile: row.mobile,
  email: row.email, status: row.status, note: row.note, createdAt: iso(row.created_at),
});
const verifDto = (row) => row && ({
  id: row.id, fullName: row.full_name, birthDate: row.birth_date, phone: row.phone,
  address: row.address, status: row.status, note: row.note,
  createdAt: iso(row.created_at), reviewedAt: iso(row.reviewed_at),
});
const notifDto = (row, readIds) => ({
  id: row.id, type: row.type, title: row.title, body: row.body,
  read: readIds.has(row.id), createdAt: iso(row.created_at),
});

async function notify(userId, type, title, body) {
  await data(admin.from('notifications').insert({ user_id: userId, type, title, body }));
}

function throttle(key, max = 10, windowMs = 15 * 60 * 1000) {
  const now = Date.now();
  const attempts = throttle.attempts || (throttle.attempts = new Map());
  const recent = (attempts.get(key) || []).filter((time) => now - time < windowMs);
  if (recent.length >= max) throw new HttpError(429, 'Too many attempts. Please try again later.');
  recent.push(now);
  attempts.set(key, recent);
}

route('POST', '/api/auth/signup', { auth: false }, async ({ body, ip }) => {
  throttle(`signup:${ip}`, 20);
  const d = new Validator(body).text('fullName', 'Full name', { min: 2, max: 100 })
    .email('email').mobile('phone', 'Phone number', { required: false }).password('password').done();
  const existing = await data(admin.from('profiles').select('id').eq('email', d.email).maybeSingle());
  if (existing) throw new HttpError(409, 'That email is already registered', { email: 'Email already registered' });
  const { data: result, error } = await createPublicClient().auth.signUp({
    email: d.email, password: d.password,
    options: { data: { full_name: d.fullName, phone: d.phone } },
  });
  if (error) throw authError(error, 422);
  const profile = result.user && await profileForAuthId(result.user.id);
  return {
    status: 201,
    body: {
      token: result.session?.access_token || null,
      user: profile ? await userDto(profile) : null,
      ...(result.session ? {} : { message: 'Check your email to confirm your account.' }),
    },
  };
});

route('POST', '/api/auth/login', { auth: false }, async ({ body, ip }) => {
  let identifier = String(body?.identifier ?? body?.email ?? '').trim().toLowerCase();
  const password = String(body?.password ?? '');
  if (!identifier || !password) throw new HttpError(422, 'Enter your email and password', {
    identifier: identifier ? undefined : 'Required', password: password ? undefined : 'Required',
  });
  throttle(`login:${ip}:${identifier}`);
  if (!identifier.includes('@')) {
    const phone = identifier.replace(/[\s-]/g, '').replace(/^\+?63(?=9\d{9}$)/, '0');
    const profile = await data(admin.from('profiles').select('email').eq('phone', phone).maybeSingle());
    if (!profile) throw new HttpError(401, 'Incorrect email or password');
    identifier = profile.email;
  }
  const { data: result, error } = await createPublicClient().auth.signInWithPassword({ email: identifier, password });
  if (error) throw authError(error, 401);
  const profile = await profileForAuthId(result.user.id);
  if (!profile) throw new HttpError(500, 'Your profile could not be loaded');
  return { body: { token: result.session.access_token, user: await userDto(profile) } };
});

route('POST', '/api/auth/forgot', { auth: false }, async ({ body, ip }) => {
  throttle(`forgot:${ip}`, 8);
  const { email } = new Validator(body).email('email').done();
  const { error } = await createPublicClient().auth.resetPasswordForEmail(email);
  if (error) throw authError(error);
  return { body: { message: 'If that email is registered, a reset code has been sent.' } };
});

route('POST', '/api/auth/reset', { auth: false }, async ({ body, ip }) => {
  throttle(`reset:${ip}`, 15);
  const v = new Validator(body).email('email').text('code', 'Code', { min: 6, max: 6 })
    .password('newPassword').done();
  const client = createPublicClient();
  const { error } = await client.auth.verifyOtp({ email: v.email, token: v.code, type: 'recovery' });
  if (error) throw authError(error, 400);
  const { error: updateError } = await client.auth.updateUser({ password: v.newPassword });
  if (updateError) throw authError(updateError, 400);
  return { body: { message: 'Password updated. You can log in now.' } };
});

route('GET', '/api/me', async ({ user }) => ({ body: { user: await userDto(user) } }));
route('PATCH', '/api/me', async ({ user, body }) => {
  const d = new Validator(body).text('fullName', 'Full name', { min: 2, max: 100 })
    .mobile('phone', 'Phone number', { required: false }).done();
  const profile = await data(admin.from('profiles').update({ full_name: d.fullName, phone: d.phone })
    .eq('id', user.id).select('*').single());
  return { body: { user: await userDto(profile) } };
});

route('GET', '/api/appointments/availability', async ({ query, user }) => {
  const { date } = new Validator(query).date('date', 'Date').done();
  const rows = await data(createPublicClient(user.accessToken).rpc('get_appointment_availability', { p_date: date }));
  const slots = rows.map((row) => ({ time: String(row.slot_time).slice(0, 5), remaining: Number(row.remaining) }));
  return { body: { date, open: slots.length > 0, slots } };
});
route('GET', '/api/appointments', async ({ user }) => {
  const rows = await data(admin.from('appointments').select('*').eq('user_id', user.id)
    .order('preferred_date', { ascending: false }).order('preferred_time', { ascending: false }));
  return { body: { appointments: rows.map(apptDto) } };
});
route('POST', '/api/appointments', async ({ user, body }) => {
  const now = nowIn('Asia/Manila');
  const d = new Validator(body).text('fullName', 'Full name', { min: 2, max: 100 })
    .mobile('phone', 'Phone number').date('date', 'Preferred date', { min: now.date })
    .oneOf('time', 'Preferred time', SLOTS).done();
  if (d.date === now.date && d.time <= now.time) throw new HttpError(422, 'That time is not available', { time: 'Pick a future time slot' });
  const row = await data(createPublicClient(user.accessToken).rpc('book_appointment', {
    p_full_name: d.fullName, p_phone: d.phone, p_date: d.date, p_time: d.time,
  }));
  return { status: 201, body: { appointment: apptDto(row) } };
});
route('POST', '/api/appointments/:id/cancel', async ({ user, params }) => {
  const row = await data(createPublicClient(user.accessToken).rpc('cancel_appointment', { p_id: params.id }));
  return { body: { appointment: apptDto(row) } };
});

route('GET', '/api/blood-requests', async ({ user }) => {
  const rows = await data(admin.from('blood_requests').select('*').eq('user_id', user.id).order('id', { ascending: false }));
  return { body: { requests: rows.map(bloodDto) } };
});
route('POST', '/api/blood-requests', async ({ user, body }) => {
  const d = new Validator(body)
    .text('patientName', 'Patient name', { min: 2, max: 100 }).text('contactPerson', 'Contact person', { min: 2, max: 100 })
    .mobile('contactNumber', 'Contact number').oneOf('bloodGroup', 'Blood group', BLOOD_GROUPS)
    .int('units', 'Units', { min: 1, max: 10, fallback: 1 }).text('hospital', 'Hospital', { max: 150, required: false })
    .text('address', 'Address', { min: 3, max: 250 }).text('city', 'City', { min: 2, max: 100 })
    .oneOf('urgency', 'Urgency', ['emergency', 'urgent', 'scheduled'], { required: false, fallback: 'emergency' })
    .text('notes', 'Notes', { max: 500, required: false }).done();
  const row = await data(createPublicClient(user.accessToken).rpc('create_blood_request', {
    p_patient_name: d.patientName, p_contact_person: d.contactPerson, p_contact_number: d.contactNumber,
    p_blood_group: d.bloodGroup, p_units: d.units, p_hospital: d.hospital, p_address: d.address,
    p_city: d.city, p_urgency: d.urgency, p_notes: d.notes,
  }));
  return { status: 201, body: { request: bloodDto(row) } };
});
route('POST', '/api/blood-requests/:id/cancel', async ({ user, params }) => {
  const row = await data(createPublicClient(user.accessToken).rpc('cancel_blood_request', { p_id: params.id }));
  return { body: { request: bloodDto(row) } };
});

function saveImage(field, dataUrl) {
  const base64 = String(dataUrl || '').replace(/^data:[^;]+;base64,/, '');
  if (!base64) throw new HttpError(422, 'Please upload both sides of your ID', { [field]: 'Upload required' });
  const buffer = Buffer.from(base64, 'base64');
  if (buffer.length > 6 * 1024 * 1024) throw new HttpError(413, 'Image is too large (max 6 MB)', { [field]: 'Max 6 MB' });
  const isJpg = buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff;
  const isPng = buffer.subarray(0, 4).equals(Buffer.from([0x89, 0x50, 0x4e, 0x47]));
  if (!isJpg && !isPng) throw new HttpError(422, 'Only JPG or PNG images are accepted', { [field]: 'JPG or PNG only' });
  return { buffer, extension: isPng ? 'png' : 'jpg', contentType: isPng ? 'image/png' : 'image/jpeg' };
}

route('GET', '/api/donor-verification', async ({ user }) => {
  const row = await data(admin.from('donor_verifications').select('*').eq('user_id', user.id)
    .order('id', { ascending: false }).limit(1).maybeSingle());
  return { body: { verification: verifDto(row) || null } };
});
route('POST', '/api/donor-verification', async ({ user, body }) => {
  const now = nowIn('Asia/Manila');
  const validator = new Validator(body).text('fullName', 'Complete name', { min: 2, max: 100 })
    .date('birthDate', 'Date of birth', { max: now.date }).mobile('phone', 'Phone number')
    .text('address', 'Current address', { min: 5, max: 250 });
  if (validator.out.birthDate) {
    const age = ageOn(validator.out.birthDate, now.date);
    if (age < 18 || age > 65) validator.fail('birthDate', 'Donors must be between 18 and 65 years old');
  }
  const d = validator.done();
  const latest = await data(admin.from('donor_verifications').select('status').eq('user_id', user.id)
    .order('id', { ascending: false }).limit(1).maybeSingle());
  if (latest && ['pending', 'approved'].includes(latest.status)) {
    throw new HttpError(409, latest.status === 'approved' ? 'You are already a verified donor' : 'Your verification is already under review');
  }
  const uploaded = [];
  try {
    const paths = {};
    for (const [field, key] of [['idFront', 'front'], ['idBack', 'back']]) {
      const image = saveImage(field, body[field]);
      const path = `${user.authUserId}/${crypto.randomBytes(16).toString('hex')}.${image.extension}`;
      await data(admin.storage.from('donor-ids').upload(path, image.buffer, {
        contentType: image.contentType, upsert: false,
      }));
      uploaded.push(path);
      paths[key] = path;
    }
    const row = await data(admin.from('donor_verifications').insert({
      user_id: user.id, full_name: d.fullName, birth_date: d.birthDate, phone: d.phone,
      address: d.address, id_front_path: paths.front, id_back_path: paths.back,
    }).select('*').single());
    return { status: 201, body: { verification: verifDto(row) } };
  } catch (error) {
    if (uploaded.length) await admin.storage.from('donor-ids').remove(uploaded);
    throw error;
  }
});

route('GET', '/api/cards/types', async () => {
  const rows = await data(admin.from('card_types').select('*').order('sort_order'));
  return { body: { cards: rows.map((row) => ({
    code: row.code, name: row.name, price: row.price, color: row.color, benefits: row.benefits,
  })) } };
});
route('GET', '/api/card-requests', async ({ user }) => {
  const rows = await data(admin.from('card_requests').select('*, card_types(name)')
    .eq('user_id', user.id).order('id', { ascending: false }));
  return { body: { requests: rows.map(cardReqDto) } };
});
route('POST', '/api/card-requests', async ({ user, body }) => {
  const now = nowIn('Asia/Manila');
  const types = await data(admin.from('card_types').select('code'));
  const d = new Validator(body).text('fullName', 'Full name', { min: 2, max: 100 })
    .date('birthDate', 'Date of birth', { max: now.date, min: '1900-01-01' })
    .oneOf('cardCode', 'Card type', types.map((row) => row.code))
    .mobile('mobile').email('email', { required: false }).done();
  const pending = await data(admin.from('card_requests').select('id').eq('user_id', user.id)
    .eq('status', 'awaiting_review').maybeSingle());
  if (pending) throw new HttpError(409, 'You already have a card request awaiting review');
  const row = await data(admin.from('card_requests').insert({
    user_id: user.id, card_code: d.cardCode, full_name: d.fullName,
    birth_date: d.birthDate, mobile: d.mobile, email: d.email,
  }).select('*, card_types(name)').single());
  return { status: 201, body: { request: cardReqDto(row) } };
});

route('GET', '/api/notifications', async ({ user }) => {
  const rows = await data(admin.from('notifications').select('*').or(`user_id.is.null,user_id.eq.${user.id}`)
    .order('id', { ascending: false }).limit(50));
  const reads = rows.length ? await data(admin.from('notification_reads').select('notification_id')
    .eq('user_id', user.id).in('notification_id', rows.map((row) => row.id))) : [];
  const readIds = new Set(reads.map((row) => row.notification_id));
  return { body: { notifications: rows.map((row) => notifDto(row, readIds)), unreadCount: await unreadCount(user.id) } };
});
route('POST', '/api/notifications/read-all', async ({ user }) => {
  await data(createPublicClient(user.accessToken).rpc('mark_all_notifications_read'));
  return { body: { unreadCount: 0 } };
});
route('POST', '/api/notifications/:id/read', async ({ user, params }) => {
  const row = await data(admin.from('notifications').select('id').eq('id', params.id)
    .or(`user_id.is.null,user_id.eq.${user.id}`).maybeSingle());
  if (!row) throw new HttpError(404, 'Notification not found');
  await data(admin.from('notification_reads').upsert({ user_id: user.id, notification_id: row.id }, {
    onConflict: 'user_id,notification_id', ignoreDuplicates: true,
  }));
  return { body: { unreadCount: await unreadCount(user.id) } };
});

const ADMIN = {
  'card-requests': { table: 'card_requests', statuses: ['awaiting_review', 'approved', 'rejected', 'issued'], label: 'Card request' },
  'donor-verifications': { table: 'donor_verifications', statuses: ['pending', 'approved', 'rejected'], label: 'Donor verification' },
  appointments: { table: 'appointments', statuses: ['pending', 'confirmed', 'cancelled', 'completed'], label: 'Appointment' },
  'blood-requests': { table: 'blood_requests', statuses: ['open', 'fulfilled', 'cancelled', 'rejected'], label: 'Blood request' },
};
route('GET', '/api/admin/files/:name', { admin: true }, async ({ params }) => {
  if (!/^[0-9a-f-]{36}\/[a-f0-9]{32}\.(jpg|png)$/i.test(params.name)) throw new HttpError(404, 'Not found');
  const { data: file, error } = await admin.storage.from('donor-ids').download(params.name);
  if (error || !file) throw new HttpError(404, 'Not found');
  return { raw: Buffer.from(await file.arrayBuffer()), contentType: params.name.endsWith('.png') ? 'image/png' : 'image/jpeg' };
});
route('GET', '/api/admin/:resource', { admin: true }, async ({ params, query }) => {
  const config = ADMIN[params.resource];
  if (!config) throw new HttpError(404, 'Unknown resource');
  let request = admin.from(config.table).select('*').order('id', { ascending: false }).limit(200);
  if (query.status && config.statuses.includes(query.status)) request = request.eq('status', query.status);
  return { body: { items: await data(request) } };
});
route('PATCH', '/api/admin/:resource/:id', { admin: true }, async ({ params, body }) => {
  const config = ADMIN[params.resource];
  if (!config) throw new HttpError(404, 'Unknown resource');
  const d = new Validator(body).oneOf('status', 'Status', config.statuses)
    .text('note', 'Note', { max: 300, required: false }).done();
  const old = await data(admin.from(config.table).select('*').eq('id', params.id).maybeSingle());
  if (!old) throw new HttpError(404, `${config.label} not found`);
  const row = await data(admin.from(config.table).update({ status: d.status, note: d.note })
    .eq('id', old.id).select('*').single());
  if (config.table !== 'donor_verifications') {
    const pretty = d.status.replace('_', ' ');
    await notify(old.user_id, 'update', `${config.label} ${pretty}`, d.note || `Your ${config.label.toLowerCase()} is now ${pretty}.`);
  }
  return { body: { item: row } };
});

module.exports = { routes, adminClient: admin, profileForAuthId };