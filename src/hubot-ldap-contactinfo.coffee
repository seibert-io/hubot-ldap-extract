# Description
#   Fetch contact information from an ldap server
#
# Configuration:
#   LDAP_URL - the URL to the LDAP server
#   LDAP_BIND_DN - bind DN used for LDAP connection
#   LDAP_BIND_SECRET - bind password used for LDAP connection
#   LDAP_SEARCH_BASE_DN - search base for contact information
#   LDAP_SEARCH_FILTER - search filter to be used, use {{searchTerm}} as placeholder for the user's search query
#   MUSTACHE_TPL - Mustache template to be used to present matching information to the user
# Commands:
#   hubot contact <search> - Find contacts matching the seach given query
#

LDAP = require 'ldapjs'
Q = require 'q'
Milk = require 'milk'
robot = null



ldapURL = process.env.LDAP_URL or "ldap://127.0.0.1:1389"
tlsMode = process.env.LDAP_TLSMODE or "plain"
caCert = process.env.LDAP_CA_CERT or ""
bindDn = process.env.LDAP_BIND_DN or "cn=root"
bindSecret = process.env.LDAP_BIND_SECRET or "secret"
baseDn = process.env.LDAP_SEARCH_BASE_DN or "o=myhost"
searchFilter = process.env.LDAP_SEARCH_FILTER or "(&(objectclass=person)(cn=*{{searchTerm}}*))"
mustacheTpl = process.env.LDAP_RESULT_MUSTACHE_TPL or "{{cn}}"

opts = {
  url: ldapURL
}

if tlsMode == "tls"
  opts['cas'] = [caCert]

client = LDAP.createClient opts


startTLSIfConfigured = () ->
  deferred = Q.defer()
  console.log "8"
  if tlsMode == "starttls"
    console.log "9"
    tlsOpts = {
      cas: [caCert]
    }
    client.starttls tlsOpts, [], (err, res) ->
      console.log "10"
      if err
        deferred.reject err
      console.log "11"
      deferred.resolve true
  else
    console.log "12"
    deferred.resolve true

  console.log "13"
  return deferred.promise

searchLdap = (searchTerm) ->
  deferred = Q.defer()
  console.log "1"
  startTLSIfConfigured()
  .fail (err) ->
    console.log "2"
    deferred.reject err
  .then ->
    console.log "3"
    client.bind bindDn, bindSecret, (err) ->
      console.log "4"
      if err
        deferred.reject err
      console.log "5"
      opts = {
        filter: searchFilter.replace "{{searchTerm}}", searchTerm
        scope: 'sub'
        paged: false
      }

      client.search baseDn, opts, (err, res) ->
        console.log "6"
        if err
          deferred.reject err

        entries = []

        res.on 'error', (err) ->
          deferred.reject err

        res.on 'searchEntry', (entry) ->
          entries.push entry.object

        res.on 'end', (result) ->

          setTimeout ->
            deferred.resolve entries
          ,0
  console.log "7"
  return deferred.promise



formatContact = (contact) ->
  return Milk.render(mustacheTpl, contact)


module.exports = (currentRobot) ->
  robot = currentRobot

  robot.respond /contact (.+)/i, (msg) ->
    sContact = msg.match[1].trim()

    console.log "-1"
    console.log searchLdap
    searchLdap sContact
      .fail (err) ->
        console.log "-2"
        console.error err
        msg.reply "Sorry, I can't search for contact information at the moment."
      .then (fContacts) ->
        console.log "-3"
        if Object.keys(fContacts).length == 0
          msg.reply "Sorry, I can't find any contact matching your search \"#{sContact}\""
        else
          results = []
          numDisplayResults = Math.min 5, fContacts.length

          for i in [0..numDisplayResults]
            fContact = fContacts[i]
            results.push formatContact(fContact)

          msg.reply results.join("\n\n").trim()
