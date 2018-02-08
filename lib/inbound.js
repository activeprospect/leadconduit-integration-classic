const xmlbuilder = require('xmlbuilder');
const default_inbound = require('leadconduit-default').inbound;

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
  request: default_inbound.request,
  response
};

// This handles the logic around creating the reason tag
const buildXml = (vars) => {

  const url = `https://app.leadconduit.com/leads?id=${vars.lead.id}`;
  const xml = xmlbuilder
    .create('response', {headless: true})
    .dtd('https://app.leadconduit.com/dtd/response-v2-basic.dtd').up()
    .element('result', vars.outcome).up();

  if (vars.reason) { xml.ele('reason', vars.reason); }
  xml.element('leadId', vars.lead.id).up()
    .element('url').dat(url);

  return xml.end({pretty: true});
};
