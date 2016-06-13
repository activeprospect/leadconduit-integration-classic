assert = require('chai').assert
mimecontent = require('mime-content')
integration = require('../src/outbound')
parser = require('leadconduit-integration').test.types.parser(integration.request.variables())

variables = ->
  parser
    xxAccountId: '00abc'
    xxCampaignId: '00xyz'
    lead:
      first_name: 'Walter'
      last_name: 'White'
      email: 'ww@a1a.com'
      phone_1: '5127891111'
      mortgage:
        property:
          city: 'Austin'
    classic:
      custom:
        favorite_color: 'yellow'
        last_name: 'Black'

describe 'LeadConduit Classic Request', ->
  request = null

  beforeEach ->
    request = integration.request(variables())

  it 'should have url', ->
    assert.equal request.url, 'https://app.leadconduit.com/v2/PostLeadAction'

  it 'should be post', ->
    assert.equal request.method, 'POST'

  it 'should accept XML', ->
    assert.equal request.headers.Accept, 'application/xml'

  it 'should have the right content-type', ->
    assert.equal request.headers['Content-Type'], 'application/x-www-form-urlencoded'

  it 'body should include xxAccountId', ->
    assert.include request.body, 'xxAccountId=00abc'

  it 'body should include xxCampaignId', ->
    assert.include request.body, 'xxCampaignId=00xyz'

  it 'body should not include xxSiteId when not given', ->
    assert.notInclude request.body, 'xxSiteId'

  it 'body should include xxSiteId when given', ->
    vars = variables()
    vars['xxSiteId'] = '00lmn'
    request = integration.request(vars)
    assert.include request.body, 'xxSiteId=00lmn'

  it 'body should include all lead parameters', ->
    assert.include request.body, 'first_name=Walter&last_name=Black&email=ww%40a1a.com&phone_1=5127891111'

  it 'body should include nested object parameters', ->
    assert.include request.body, 'mortgage.property.city=Austin'

  it 'body should include custom fields', ->
    assert.include request.body, 'favorite_color=yellow'

  it 'custom fields should overwrite default fields', ->
    assert.include request.body, 'last_name=Black'

  it 'should allow null attributes without error', ->
    vars = variables()
    vars['lead']['nullfield'] = null
    request = integration.request(vars)
    assert.include request.body, 'nullfield='

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
      lead:
        id: '0552p8csp'
        url: 'http://app.leadconduit.com/leads?id=0552p8csp'

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
      lead:
        id: '0552p8csp'
        url: 'http://app.leadconduit.com/leads?id=0552p8csp'

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