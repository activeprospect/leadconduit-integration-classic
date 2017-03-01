mimecontent = require('mime-content')
querystring = require('querystring')
flat = require('flat')
baseUrl = 'https://app.leadconduit.com/v2/PostLeadAction'

#
# Request Function -------------------------------------------------------
#

request = (vars) ->

  # LCC routing parameters
  content = {
    xxAccountId:  vars.xxAccountId
    xxCampaignId: vars.xxCampaignId
  }
  content['xxSiteId'] = vars.xxSiteId if vars.xxSiteId?

  # build lead data
  for key, value of flat.flatten(vars.lead)
    content[key] = value?.valueOf()

  if vars.classic?.custom
    for key, value of flat.flatten(vars.classic.custom, safe: true)
      content[key] = value?.valueOf() if value?

  # URL encoded post body
  content = querystring.encode(content)

  url: baseUrl
  method: 'POST'
  headers:
    Accept: 'application/xml'
    'Content-Type': 'application/x-www-form-urlencoded'

  body: content


request.variables = ->
  [
    { name: 'xxAccountId',  type: 'string', required: true,  description: 'LeadConduit Classic account ID' },
    { name: 'xxCampaignId', type: 'string', required: true,  description: 'LeadConduit Classic campaign ID' }
    { name: 'xxSiteId',     type: 'string', required: false, description: 'LeadConduit Classic site ID' }
    { name: 'classic.custom.*', type: 'wildcard', required: false }
  ]


#
# Response Function ------------------------------------------------------
#

response = (vars, req, res) ->
  if res.status == 200
    doc = mimecontent(res.body, 'text/xml')
    event = doc.toObject(explicitArray: false, explicitRoot: false, mergeAttrs: true)
    event['outcome'] = event.result
    event['lead'] = { id: event.leadId, url: event.url }
    event.reason = event.reason.sort().toString() if Array.isArray(event.reason)
    delete event.result
    delete event.leadId
    delete event.url
    event
  else
    { outcome: 'error', reason: "LeadConduit Classic error (#{res.status})" }

response.variables = ->
  [
    { name: 'outcome', type: 'string', description: 'lead-processing result' }
    { name: 'reason', type: 'string', description: 'in case of failure, the reason for failure' }
    { name: 'lead.id', type: 'string', description: 'ID of the lead in LeadConduit Classic' }
    { name: 'lead.url', type: 'string', description: 'URL of the lead in LeadConduit Classic' }
  ]

#
# Exports ----------------------------------------------------------------
#

module.exports =
  request: request,
  response: response


