import assert from 'node:assert/strict'
import test from 'node:test'

import {
  extractBearerToken,
  isAllowedGeminiTarget,
  isAnonymousCredential,
} from './request_policy.ts'

test('extractBearerToken accepts only a non-empty Bearer credential', () => {
  assert.equal(extractBearerToken('Bearer user.jwt.token'), 'user.jwt.token')
  assert.equal(extractBearerToken('bearer\tuser.jwt.token'), 'user.jwt.token')
  assert.equal(extractBearerToken(null), null)
  assert.equal(extractBearerToken(''), null)
  assert.equal(extractBearerToken('Basic abc'), null)
  assert.equal(extractBearerToken('Bearer '), null)
  assert.equal(extractBearerToken('Bearer token trailing'), null)
})

test('Gemini target policy allows only the production model and endpoint', () => {
  assert.equal(
    isAllowedGeminiTarget('gemini-2.5-flash', 'generateContent'),
    true,
  )
  assert.equal(
    isAllowedGeminiTarget('gemini-2.5-pro', 'generateContent'),
    false,
  )
  assert.equal(
    isAllowedGeminiTarget('gemini-2.5-flash', 'streamGenerateContent'),
    false,
  )
  assert.equal(
    isAllowedGeminiTarget('../gemini-2.5-flash', 'generateContent'),
    false,
  )
})

test('the project anon key is never treated as a user credential', () => {
  assert.equal(isAnonymousCredential('anon-key', 'anon-key'), true)
  assert.equal(isAnonymousCredential('user.jwt.token', 'anon-key'), false)
})
