module.exports = {
  outbound: require('./lib/outbound'),
  inbound: {
    post: require('./lib/inbound')
  }
};
