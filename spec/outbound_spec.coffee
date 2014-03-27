assert = require('chai').assert
mimecontent = require('mime-content')
integration = require('../src/outbound')

describe 'LeadConduit Classic Request', ->
  request = null

  beforeEach ->
    request = integration.request(xxAccountId: '00abc', xxCampaignId: '00xyz')

  it 'should have url', ->
    assert.equal 'https://app.leadconduit.com/v2/PostLeadAction?xxAccountId=00abc&xxCampaignId=00xyz', request.url

  it 'should be post', ->
    assert.equal 'POST', request.method

  it 'should accept XML', ->
    assert.equal 'application/xml', request.headers.Accepts


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
      leadId: '0552p8csp'
      result: 'success'
      url: "http://app.leadconduit.com/leads?id=0552p8csp"
    response = integration.response(vars, req, res)
    assert.deepEqual expected, response

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
      leadId: '0552p8csp'
      result: "failure"
      reason: 'missing email'
      url: "http://app.leadconduit.com/leads?id=0552p8csp"
    response = integration.response(vars, req, res)
    assert.deepEqual expected, response

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
    assert.deepEqual expected, response