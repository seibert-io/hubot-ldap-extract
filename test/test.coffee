Helper = require('hubot-test-helper')
expect = require('chai').expect
LDAP = require 'ldapjs'
Milk = require 'milk'

helper = new Helper '../src/hubot-ldap-contactinfo.coffee'
server = LDAP.createServer()


mustacheTpl = process.env['LDAP_RESULT_MUSTACHE_TPL'] = '{{cn}}';
process.env['LDAP_SEARCH_FILTER'] = "(&(objectclass=person)(cn=*{{searchTerm}}*))"

server.bind 'cn=root', (req, res, next) ->
  res.end();
  return next();

server.search 'o=example', (req, res, next) ->
  res.end();

server.listen 1389, '127.0.0.1', () ->
   console.log 'LDAP server listening at: ' + server.url


mockUsers = {
    developherr: {
      dn: 'cn=developherr, ou=users, o=myhost'
      attributes: {
        cn: 'developherr'
        name: 'Firstname'
        lname: 'Lastname'
        objectclass: 'person'
      }
    },
    developer: {
      dn: 'cn=developer, ou=users, o=myhost'
      attributes: {
        cn: 'developer'
        name: 'Firstname'
        lname: 'Lastname'
        objectclass: 'person'
      }
    }
}
addMockUsers = (req, res, next) ->
  req.users = mockUsers

  return next();


server.search 'o=myhost', [addMockUsers], (req, res, next) ->
  Object.keys(req.users).forEach (k) ->
    if req.filter.matches req.users[k].attributes
      res.send req.users[k];

  res.end();
  return next();


describe 'hubot-ldap-contactinfo', ->
  room = null

  beforeEach ->
    @room = helper.createRoom()

  afterEach ->
    @room.destroy()

  context 'testing successful search', ->
    beforeEach (done) ->
      @room.user.say 'user1', 'hubot contact developherr'
      setTimeout done, 100

    it 'should return LDAP entries corresponding to search \'developherr\'', ->
      expect(@room.messages.pop()[1]).to.eql '@user1 ' + Milk.render(mustacheTpl, mockUsers.developherr.attributes)


  context 'testing successful search with multiple results', ->
    beforeEach (done) ->
      @room.user.say 'user1', 'hubot contact evelop'
      setTimeout done, 100

    it 'should return LDAP entries corresponding to search \'evelop\'', ->
      expect(@room.messages.pop()[1]).to.eql '@user1 ' + Milk.render(mustacheTpl, mockUsers.developherr.attributes) + "\n\n" + Milk.render(process.env.MUSTACHE_TPL, mockUsers.developer.attributes)


  context 'testing insuccessful search', ->
    beforeEach (done) ->
      @room.user.say 'user1', 'hubot contact non-existing'
      setTimeout done, 100

    it 'should not return any LDAP entries corresponding to search \'non-existing\'', ->
      expect(@room.messages.pop()[1]).to.eql '@user1 Sorry, I can\'t find any contact matching your search "non-existing\"'
