const mimecontent = require('mime-content');
const querystring = require('querystring');
const flat = require('flat');
const _ = require('lodash');

const baseUrl = 'https://classic.leadconduit.com/v2/PostLeadAction';

const request = (vars) => {

  // LCC routing parameters
  let content = {
    xxAccountId:  vars.xxAccountId,
    xxCampaignId: vars.xxCampaignId
  };

  if (vars.xxSiteId) content['xxSiteId'] = vars.xxSiteId;

  // build lead data
  const leadMap = new Map(Object.entries(flat.flatten(vars.lead)));
  leadMap.forEach((value, key) => content[key] = (value) ? value.valueOf(): undefined);

  const customData = _.get(vars, 'classic.custom', {});
  const customMap = new Map(Object.entries(flat.flatten(customData, {safe: true})));
  customMap.forEach((value, key) => content[key] = (value) ? value.valueOf(): undefined);

  return {
    url: baseUrl,
    method: 'POST',
    headers: {
      Accept: 'application/xml',
      'Content-Type': 'application/x-www-form-urlencoded'
    },
    body: querystring.encode(content)
  };
};


request.variables = () => [
  { name: 'xxAccountId',  type: 'string', required: true,  description: 'LeadConduit Classic account ID' },
  { name: 'xxCampaignId', type: 'string', required: true,  description: 'LeadConduit Classic campaign ID' },
  { name: 'xxSiteId',     type: 'string', required: false, description: 'LeadConduit Classic site ID' },
  { name: 'classic.custom.*', type: 'wildcard', required: false }
];


const response = (vars, req, res) => {
  if (res.status == 200) {
    const doc = mimecontent(res.body, 'text/xml');
    const event = doc.toObject({explicitArray: false, explicitRoot: false, mergeAttrs: true});
    event['outcome'] = event.result;
    event['lead'] = { id: event.leadId, url: event.url };

    if (Array.isArray(event.reason)) {
      event.reason = event.reason.sort().toString();
    }
    delete event.result;
    delete event.leadId;
    delete event.url;
    return event;
  } else {
    return { outcome: 'error', reason: `LeadConduit Classic error (${res.status})` };
  }
};


response.variables = () => [
  { name: 'outcome', type: 'string', description: 'lead-processing result' },
  { name: 'reason', type: 'string', description: 'in case of failure, the reason for failure' },
  { name: 'lead.id', type: 'string', description: 'ID of the lead in LeadConduit Classic' },
  { name: 'lead.url', type: 'string', description: 'URL of the lead in LeadConduit Classic' }
];


module.exports = {
  request,
  response
};
