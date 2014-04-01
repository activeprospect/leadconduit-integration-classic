mimecontent = require('mime-content')
querystring = require('querystring')
baseUrl = 'https://app.leadconduit.com/v2/PostLeadAction'

#
# Request Function -------------------------------------------------------
#

request = (vars) ->

  # build lead data
  content = {}
  for key, value of vars.lead
    content[key] = value?.normal or value?.raw or value

  # URL encoded post body
  content = querystring.encode(content)

  url: "#{baseUrl}?xxAccountId=#{vars.xxAccountId}&xxCampaignId=#{vars.xxCampaignId}"
  method: 'POST'
  headers:
    Accept: 'application/xml'
    'Content-Type': 'application/x-www-form-urlencoded'

  body: content


request.variables = ->
  [
    { name: 'xxAccountId', type: 'string', required: true, description: 'LeadConduit Classic account ID' },
    { name: 'xxCampaignId', type: 'string', required: true, description: 'LeadConduit Classic campaign ID' }
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
    { lead:
      [
        { name: 'id', type: 'string', description: 'ID of the lead in LeadConduit Classic' }
        { name: 'url', type: 'string', description: 'URL of the lead in LeadConduit Classic' }
      ]
    }
  ]

#
# Exports ----------------------------------------------------------------
#

module.exports =
  request: request,
  response: response


