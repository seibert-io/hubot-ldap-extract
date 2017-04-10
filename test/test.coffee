Helper = require('hubot-test-helper')
expect = require('chai').expect
LDAP = require 'ldapjs'
any = require 'any'
Handlebars = require 'handlebars'
HandlebarsHelpers = require 'handlebars-helpers'

fs = require 'fs'

helper = new Helper '../src/hubot-ldap-extract.coffee'


process.env['LDAP_SEARCH_FILTER'] = "(&(objectClass=person)(cn=*{{searchTerm}}*))"
process.env['LDAP_LISTENING_TRIGGER'] = '(contact|ldap|test-developherr)';
tpl = process.env['LDAP_RESULT_TPL'] = '{{cn}}';

tpl = Handlebars.compile tpl, {helpers: HandlebarsHelpers()}

server = LDAP.createServer {}

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
        objectClass: ['person', 'testA']
      }
    },
    developer: {
      dn: 'cn=developer, ou=users, o=myhost'
      attributes: {
        cn: 'developer'
        name: 'Firstname'
        lname: 'Lastname'
        objectClass: ['person', 'testB']
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

describe 'hubot-ldap-extract', ->
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
      expect(@room.messages.pop()[1]).to.eql '@user1 ' + tpl(mockUsers.developherr.attributes)


  context 'testing successful search with multiple results', ->
    beforeEach (done) ->
      @room.user.say 'user1', 'hubot ldap evelop'
      setTimeout done, 100

    it 'should return LDAP entries corresponding to search \'evelop\'', ->
      expect(@room.messages.pop()[1]).to.eql '@user1 ' + tpl(mockUsers.developherr.attributes) + "\n\n" + tpl(mockUsers.developer.attributes)


  context 'testing insuccessful search', ->
    beforeEach (done) ->
      @room.user.say 'user1', 'hubot test-developherr non-existing'
      setTimeout done, 100

    it 'should not return any LDAP entries corresponding to search \'non-existing\'', ->
      expect(@room.messages.pop()[1]).to.eql '@user1 Sorry, I can\'t find any entries matching your search "non-existing\"'
