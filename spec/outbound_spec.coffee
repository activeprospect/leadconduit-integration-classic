assert = require('chai').assert
mimecontent = require('mime-content')
integration = require('../src/outbound')

variables = ->
  xxAccountId: '00abc'
  xxCampaignId: '00xyz'
  lead:
    first_name: 'Walter'
    last_name: 'White'
    email:
      raw: 'WW@A1A.COM'
      normal: 'ww@a1a.com'
      domain: 'a1a.com'
      host: 'a1a'
      tld: 'com'
    phone_1:
      raw: '512-789-1111'
      normal: '5127891111'
      area: '512'
      exchange: '789'
      line: '1111'

describe 'LeadConduit Classic Request', ->
  request = null

  beforeEach ->
    request = integration.request(variables())

  it 'should have url', ->
    assert.equal request.url, 'https://app.leadconduit.com/v2/PostLeadAction?xxAccountId=00abc&xxCampaignId=00xyz'

  it 'should be post', ->
    assert.equal request.method, 'POST'

  it 'should accept XML', ->
    assert.equal request.headers.Accept, 'application/xml'

  it 'should have the right content-type', ->
    assert.equal request.headers['Content-Type'], 'application/x-www-form-urlencoded'

  it 'should send the lead parameters it gets', ->
    assert.equal request.body, 'first_name=Walter&last_name=White&email=ww%40a1a.com&phone_1=5127891111'

  it 'should allow null attributes without error', ->
    vars = variables()
    vars['lead']['nullfield'] = null
    request = integration.request(vars)
    assert.equal request.body, 'first_name=Walter&last_name=White&email=ww%40a1a.com&phone_1=5127891111&nullfield='

describe 'Lead Post Response', ->

  it 'should parse success response', ->
    vars = {}
    req = {}
    res =
      status: 200,
      headers:
        'Content-Type': 'application/xml'
      body: """
            <response>
              <result>success</result>
              <leadId>0552p8csp</leadId>
              <url><![CDATA[http://app.leadconduit.com/leads?id=0552p8csp]]></url>
            </response>
            """
    expected =
      outcome: 'success'
      lead: {
        id: '0552p8csp'
        url: 'http://app.leadconduit.com/leads?id=0552p8csp'
      }
    response = integration.response(vars, req, res)
    assert.deepEqual response, expected

  it 'should parse failure response', ->
    vars = {}
    req = {}
    res =
      status: 200,
      headers:
        'Content-Type': 'application/xml'
      body: """
            <response>
              <result>failure</result>
              <reason>missing email</reason>
              <leadId>0552p8csp</leadId>
              <url><![CDATA[http://app.leadconduit.com/leads?id=0552p8csp]]></url>
            </response>
            """
    expected =
      outcome: 'failure'
      reason: 'missing email'
      lead: {
        id: '0552p8csp'
        url: 'http://app.leadconduit.com/leads?id=0552p8csp'
      }
    response = integration.response(vars, req, res)
    assert.deepEqual response, expected

  it 'should return error outcome on non-200 response status', ->
    vars = {}
    req = {}
    res =
      status: 400,
      headers:
        'Content-Type': 'application/xml'
      body: ''
    expected =
      outcome: 'error'
      reason: 'LeadConduit Classic error (400)'
    response = integration.response(vars, req, res)
    assert.deepEqual response, expected