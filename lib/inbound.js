const xmlbuilder = require('xmlbuilder');
const default_inbound = require('leadconduit-default').inbound;

const request = default_inbound.request;
request.params = default_inbound.request.params;
request.variables = default_inbound.request.variables;
request.examples = default_inbound.request.examples;

const response = (req, vars) => {
  const body = buildXml(vars);

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

// This handles the logic around creating the reason tag
const buildXml = (vars) => {
  const url = `https://app.leadconduit.com/leads?id=${vars.lead.id}`;
  const xml = (vars.reason) ?
    xmlbuilder.create('response', {headless: true})
      .dtd('https://app.leadconduit.com/dtd/response-v2-basic.dtd').up()
      .ele('result', vars.outcome).up()
      .ele('reason', vars.reason).up()
      .ele('leadId', vars.lead.id).up()
      .ele('url').dat(url)
      .end({pretty:true})
    : xmlbuilder.create('response', {headless: true})
      .dtd('https://app.leadconduit.com/dtd/response-v2-basic.dtd').up()
      .ele('result', vars.outcome).up()
      .ele('leadId', vars.lead.id).up()
      .ele('url').dat(url)
      .end({pretty:true});

  return xml;
};
