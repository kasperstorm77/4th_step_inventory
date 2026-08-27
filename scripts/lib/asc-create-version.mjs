// asc-create-version.mjs — create the next App Store version record so a build
// can be attached to it.
//
// attach-appstore-build.mjs and asc-version-notes.mjs both require a version
// record that is not yet READY_FOR_SALE. After a release goes live nothing
// creates the next one, so "attach build 117 to 2.3.9" fails with "no App Store
// version 2.3.9" until someone clicks "+" in App Store Connect. This is that
// click. Idempotent: an existing editable record for the version is reported
// and left alone; a live one is an error (its build cannot change).
//
// Inputs (env): ASC_KEY, ASC_KEY_ID, ASC_ISSUER_ID,
//   ASC_BUNDLE_ID (default dk.stormstyrken.twelvestepsapp),
//   ASC_VERSION   (versionString, e.g. "2.3.9"),
//   ASC_APPLY     ("1" to write; anything else is a dry run).

import crypto from 'node:crypto'
import fs from 'node:fs'

const need = (k) => {
  const v = process.env[k]
  if (!v) {
    console.error(`asc-create-version: missing ${k}`)
    process.exit(2)
  }
  return v
}
const KEY_PATH = need('ASC_KEY')
const KEY_ID = need('ASC_KEY_ID')
const ISSUER = need('ASC_ISSUER_ID')
const BUNDLE_ID = process.env.ASC_BUNDLE_ID || 'dk.stormstyrken.twelvestepsapp'
const VERSION = need('ASC_VERSION')
const APPLY = process.env.ASC_APPLY === '1'

const b64url = (b) =>
  Buffer.from(b).toString('base64').replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
const now = Math.floor(Date.now() / 1000)
const input = `${b64url(JSON.stringify({ alg: 'ES256', kid: KEY_ID, typ: 'JWT' }))}.${b64url(
  JSON.stringify({ iss: ISSUER, iat: now, exp: now + 1200, aud: 'appstoreconnect-v1' }),
)}`
const TOKEN = `${input}.${b64url(
  crypto.sign('SHA256', Buffer.from(input), {
    key: fs.readFileSync(KEY_PATH, 'utf8'),
    dsaEncoding: 'ieee-p1363',
  }),
)}`

const API = 'https://api.appstoreconnect.apple.com/v1'
async function asc(path, opts = {}) {
  const r = await fetch(path.startsWith('http') ? path : `${API}${path}`, {
    ...opts,
    headers: {
      Authorization: `Bearer ${TOKEN}`,
      'Content-Type': 'application/json',
      ...(opts.headers || {}),
    },
  })
  const t = await r.text()
  if (!r.ok) throw new Error(`ASC ${opts.method || 'GET'} ${path} → ${r.status}: ${t.slice(0, 400)}`)
  return t ? JSON.parse(t) : {}
}

const apps = await asc(`/apps?filter[bundleId]=${encodeURIComponent(BUNDLE_ID)}&limit=1`)
const appId = apps.data?.[0]?.id
if (!appId) throw new Error(`no app for ${BUNDLE_ID}`)

const versions = await asc(
  `/apps/${appId}/appStoreVersions?limit=10&fields[appStoreVersions]=versionString,appStoreState,platform`,
)
const existing = (versions.data ?? []).find((v) => v.attributes?.versionString === VERSION)
if (existing) {
  const state = existing.attributes?.appStoreState
  if (['READY_FOR_SALE', 'REMOVED_FROM_SALE'].includes(state)) {
    throw new Error(`version ${VERSION} already exists and is ${state}`)
  }
  console.log(`✓ version ${VERSION} already exists [${state}] — nothing to create`)
  process.exit(0)
}

const editable = (versions.data ?? []).find((v) =>
  !['READY_FOR_SALE', 'REMOVED_FROM_SALE', 'DEVELOPER_REMOVED_FROM_SALE'].includes(
    v.attributes?.appStoreState,
  ),
)
if (editable) {
  throw new Error(
    `a pending version ${editable.attributes?.versionString} [${editable.attributes?.appStoreState}] already exists; ` +
      `Apple allows one editable version — rename it in App Store Connect or ship it first`,
  )
}

if (!APPLY) {
  console.log(`dry run: would create App Store version ${VERSION} (IOS) for app ${appId}`)
  console.log(`re-run with --yes to create it`)
  process.exit(0)
}

const created = await asc('/appStoreVersions', {
  method: 'POST',
  body: JSON.stringify({
    data: {
      type: 'appStoreVersions',
      attributes: { versionString: VERSION, platform: 'IOS' },
      relationships: { app: { data: { type: 'apps', id: appId } } },
    },
  }),
})
console.log(
  `✓ created version ${created.data?.attributes?.versionString} [${created.data?.attributes?.appStoreState}]`,
)
