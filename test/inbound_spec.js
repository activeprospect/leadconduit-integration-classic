const assert = require('chai').assert;
const integration = require('../lib/inbound');

describe('Inbound Response', () => {

  const vars = {
    lead: { id: '123' },
    outcome: 'Failure',
    reason: 'bad!'
  };

  it('should respond with 201', () => {
    const res = integration.response(baseRequest('application/json'), vars);
    assert.deepEqual(res.status, 201);
  });

  it('should respond with xml', () => {
    const res = integration.response(baseRequest('application/json'), vars);
    assert.deepEqual(res.headers, {'Content-Type': 'application/xml', 'Content-Length': 253});
  });

  it('should correctly parse failure outcome', () => {
    const res = integration.response(baseRequest('application/json'), vars);
    assert.deepEqual(res.body, nonSuccessBody);
  });

  it('should correctly parse success outcome', () => {
    vars.outcome = 'Success';
    delete vars.reason;

    const res = integration.response(baseRequest('application/json'), vars);
    assert.deepEqual(res.body, successBody);
  });
});


const baseRequest = (accept = null, querystring = '') => {
  return {
    uri: `/whatever${querystring}`,
    method: 'post',
    version: '1.1',
    headers: {
      'Accept': accept || 'application/xml',
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: 'first_name=Joe',
    timestamp: new Date().getTime()
  };
};

const successBody = `<!DOCTYPE response SYSTEM "https://app.leadconduit.com/dtd/response-v2-basic.dtd">
<response>
  <result>Success</result>
  <leadId>123</leadId>
  <url>
    <![CDATA[https://app.leadconduit.com/leads?id=123]]>
  </url>
</response>`;

const nonSuccessBody = `<!DOCTYPE response SYSTEM "https://app.leadconduit.com/dtd/response-v2-basic.dtd">
<response>
  <result>Failure</result>
  <reason>bad!</reason>
  <leadId>123</leadId>
  <url>
    <![CDATA[https://app.leadconduit.com/leads?id=123]]>
  </url>
</response>`;
