const default_inbound = require('leadconduit-default').inbound;

const request = default_inbound.request;
request.params = default_inbound.request.params;
request.variables = default_inbound.request.variables;
request.examples = default_inbound.request.examples;


const response = (req, vars) => {

  const reason = (vars.reason) ?
    `<reason>${vars.reason}</reason>`
    : '';

  const body =
    `
    <!DOCTYPE response SYSTEM "https://app.leadconduit.com/dtd/response-v2-basic.dtd">
      <response>
        <result>${vars.outcome}</result>
        ${reason}
        <leadId>${vars.lead.id}</leadId>
        <url><![CDATA[https://app.leadconduit.com/leads?id=${vars.lead.id}]]></url>
      </response>
    `;

  return {
    status: 201,
    headers: {
      'Content-Type': 'application/xml',
      'Content-Length': body.length
    },
    body
  };
};

response.variables = default_inbound.response.variables;

module.exports = {
  name: 'Standard',
  request,
  response
};
