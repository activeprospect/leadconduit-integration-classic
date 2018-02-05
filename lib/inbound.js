const _ = require('lodash');
const mimecontent = require('mime-content');
const mimeparse = require('mimeparse');
const flat = require('flat');
const url = require('url');
const HttpError = require('leadconduit-integration').HttpError;


const supportedMimeTypes = [
  'application/x-www-form-urlencoded',
  'application/json',
  'application/xml',
  'text/xml'
];

const supportedMimeTypeLookup = supportedMimeTypes.reduce(((lookup, mimeType) => {
  lookup[mimeType] = true;
  return lookup;
}), {});


const request = (req) => {

  // ensure supported method
  const method = (req.method) ? req.method.toLowerCase() : '';
  if (method !== 'get' && method !== 'post') {
    throw new HttpError(405, { 'Content-Type': 'text/plain', Allow: 'GET, POST' }, `The ${method.toUpperCase()} method is not allowed`);
  }

  // ensure acceptable content type, preferring JSON
  let mimeType = selectMimeType(req.headers['Accept']);
  if (!mimeType) {
    throw new HttpError(406, { 'Content-Type': 'text/plain' }, 'Not capable of generating content according to the Accept header');
  }

  // parse the query string
  const uri = url.parse(req.uri, true);
  const query = flat.unflatten(uri.query);

  // find the redir url
  let redirUrl = query.redir_url;

  if (redirUrl) {
    if (_.isArray(redirUrl)) redirUrl = redirUrl[0];
    try {
      redirUrl = url.parse(redirUrl);
      if (!redirUrl.slashes && !(redirUrl.protocol === 'http:' || redirUrl.protocol === 'https:')) {
        throw new HttpError(400, { 'Content-Type': 'text/plain' }, 'Invalid redir_url');
      }
    } catch(e) {
      throw new HttpError(400, { 'Content-Type': 'text/plain' }, 'Invalid redir_url');
    }
  }

  normalizeTrustedFormCertUrl(query);

  if (method === 'get') {
    return query;
  } else if (method === 'post') {
    if (req.headers['Content-Length'] || req.headers['Transfer-Encoding'] === 'chunked') {
    // assume a request body

    // ensure a content type header
      const contentType = req.headers['Content-Type'];
      if (!contentType) {
        throw new HttpError(415, {'Content-Type': 'text/plain'}, 'Content-Type header is required');
      }

      // ensure valid mime type
      mimeType = selectMimeType(req.headers['Content-Type']);
      if (!supportedMimeTypeLookup[mimeType]) {
        throw new HttpError(406, {'Content-Type': 'text/plain'}, `MIME type in Content-Type header is not supported. Use only ${supportedMimeTypes.join(', ')}.`);
      }

      // parse request body according the the mime type
      const body = (req.body) ? req.body.trim() : null;
      if (!body) return query;
      let parsed = mimecontent(body, mimeType);

      // if form URL encoding, convert dot notation keys
      if (mimeType === 'application/x-www-form-urlencoded') {
        parsed = flat.unflatten(parsed);
      }

      // if XML, turn doc into an object
      if (mimeType === 'application/xml' || mimeType === 'text/xml') {
        try {
          parsed = parsed.toObject({explicitArray: false, explicitRoot: false, mergeAttrs: true});
        } catch (e) {
          const xmlError = e.toString().replace(/\r?\n/g, ' ');
          throw new HttpError(400, {'Content-Type': 'text/plain'}, `Body does not contain XML or XML is unparseable -- ${xmlError}.`);
        }
      }

      // merge query string data into data parsed from request body
      _.merge(parsed, query);

      normalizeTrustedFormCertUrl(parsed);

      return parsed;
    } else {
      // assume no request body
      return query;
    }
  }
};

request.variables = () => [
  { name: '*', type: 'wildcard' }
];

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

response.variables = () => [
  { name: 'lead.id', type: 'string', description: 'The lead identifier that the source should reference' },
  { name: 'outcome', type: 'string', description: 'The outcome of the transaction (default is success)' },
  { name: 'reason', type: 'string', description: 'If the outcome was a failure, this is the reason' }
];

const selectMimeType = (contentType) => {
  contentType = (contentType || 'application/json');
  if (contentType === '*/*') contentType = 'application/json';
  return mimeparse.bestMatch(supportedMimeTypes, contentType);
};

const normalizeTrustedFormCertUrl = (obj) => {
  const urlMap = new Map(Object.entries(obj));
  for (let [param, value] of urlMap) {
    let lowerCaseParam = (param && param.toLowerCase()) ? param.toLowerCase() : null;
    if (lowerCaseParam === 'xxtrustedformcerturl') {
      obj.trustedform_cert_url = value;
      delete obj[param];
    }
  }
};


module.exports = {
  name: 'Standard',
  request,
  response
};
