'use strict';

class HttpError extends Error {
  constructor(status, message, fields) {
    super(message);
    this.status = status;
    this.fields = fields; // optional { fieldName: 'message' }
  }
}

// ---- validation helpers -------------------------------------------------------
const PH_MOBILE = /^(?:\+?63|0)9\d{9}$/;
const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/;
const BLOOD_GROUPS = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

class Validator {
  constructor(body) { this.body = body && typeof body === 'object' ? body : {}; this.errors = {}; this.out = {}; }
  fail(field, msg) { if (!this.errors[field]) this.errors[field] = msg; return this; }
  text(field, label, { min = 1, max = 200, required = true } = {}) {
    let v = this.body[field];
    v = v == null ? '' : String(v).trim().replace(/\s+/g, ' ');
    if (!v) { if (required) this.fail(field, `${label} is required`); this.out[field] = null; return this; }
    if (v.length < min) this.fail(field, `${label} must be at least ${min} characters`);
    else if (v.length > max) this.fail(field, `${label} must be at most ${max} characters`);
    this.out[field] = v; return this;
  }
  email(field, { required = true } = {}) {
    const v = String(this.body[field] ?? '').trim().toLowerCase();
    if (!v) { if (required) this.fail(field, 'Email is required'); this.out[field] = null; return this; }
    if (!EMAIL.test(v) || v.length > 254) this.fail(field, 'Enter a valid email address');
    this.out[field] = v; return this;
  }
  mobile(field, label = 'Mobile number', { required = true } = {}) {
    const raw = String(this.body[field] ?? '').replace(/[\s-]/g, '');
    if (!raw) { if (required) this.fail(field, `${label} is required`); this.out[field] = null; return this; }
    if (!PH_MOBILE.test(raw)) this.fail(field, `${label} must be a valid PH mobile (e.g. 09171234567)`);
    this.out[field] = '0' + raw.replace(/^\+?63|^0/, ''); return this;
  }
  password(field) {
    const v = String(this.body[field] ?? '');
    if (v.length < 8) this.fail(field, 'Password must be at least 8 characters');
    else if (v.length > 128) this.fail(field, 'Password is too long');
    else if (!/[A-Za-z]/.test(v) || !/\d/.test(v)) this.fail(field, 'Use letters and at least one number');
    this.out[field] = v; return this;
  }
  date(field, label, { min, max, required = true } = {}) {
    const v = String(this.body[field] ?? '').trim();
    if (!v) { if (required) this.fail(field, `${label} is required`); this.out[field] = null; return this; }
    if (!/^\d{4}-\d{2}-\d{2}$/.test(v) || Number.isNaN(Date.parse(v + 'T00:00:00Z')) ||
        new Date(v + 'T00:00:00Z').toISOString().slice(0, 10) !== v) { this.fail(field, `${label} is not a valid date`); return this; }
    if (min && v < min) this.fail(field, `${label} is too early`);
    if (max && v > max) this.fail(field, `${label} is too late`);
    this.out[field] = v; return this;
  }
  oneOf(field, label, list, { required = true, fallback = null } = {}) {
    let v = this.body[field];
    if (v == null || v === '') { if (required) this.fail(field, `${label} is required`); this.out[field] = fallback; return this; }
    v = String(v);
    if (!list.includes(v)) this.fail(field, `${label} is invalid`);
    this.out[field] = v; return this;
  }
  int(field, label, { min = 1, max = 100, fallback = 1 } = {}) {
    const raw = this.body[field];
    const v = raw == null || raw === '' ? fallback : Number(raw);
    if (!Number.isInteger(v) || v < min || v > max) this.fail(field, `${label} must be between ${min} and ${max}`);
    this.out[field] = v; return this;
  }
  done() {
    if (Object.keys(this.errors).length) throw new HttpError(422, 'Please check the highlighted fields', this.errors);
    return this.out;
  }
}

// ---- date helpers (time-zone aware) ------------------------------------------
function nowIn(tz) {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: tz, year: 'numeric', month: '2-digit', day: '2-digit',
    hour: '2-digit', minute: '2-digit', hourCycle: 'h23',
  }).formatToParts(new Date()).reduce((a, p) => (a[p.type] = p.value, a), {});
  return { date: `${parts.year}-${parts.month}-${parts.day}`, time: `${parts.hour}:${parts.minute}` };
}
function ageOn(birthISO, todayISO) {
  const [by, bm, bd] = birthISO.split('-').map(Number);
  const [ty, tm, td] = todayISO.split('-').map(Number);
  return ty - by - (tm < bm || (tm === bm && td < bd) ? 1 : 0);
}
const dayOfWeek = (iso) => new Date(iso + 'T00:00:00Z').getUTCDay(); // 0 = Sunday

module.exports = { HttpError, Validator, BLOOD_GROUPS, nowIn, ageOn, dayOfWeek };
