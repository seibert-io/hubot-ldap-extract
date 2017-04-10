# developherr/hubot-ldap-extract

A Hubot script that extracts information from an LDAP server.

Whatever information you hold available within your LDAP - Hubot can give you an overview on that information

## Installation

```npm install hubot-ldap-extract --save```

Then, add the script to the external-scripts.json file:

```
[
  "hubot-ldap-extract"
]
```

## Configuration

Configure this package by setting its corresponding environment variables:

- ```LDAP_EXTRACT_LDAPURL``` - URL of the LDAP server, including protocol and port, e.g. ```ldap://yourldaphost:389```. Make sure the protocol matches the TLS mode provided below.
- ```LDAP_EXTRACT_BIND_DN``` - bind DN used for LDAP connection
- ```LDAP_EXTRACT_BIND_SECRET``` - bind password used for LDAP connection
- ```LDAP_EXTRACT_SEARCH_BASE_DN``` - search base for contact information
- ```LDAP_EXTRACT_SEARCH_FILTER``` - search filter to be used, use {{searchTerm}} as placeholder for the user's search query, e.g. ```(uid={{searchTerm}})```
- ```LDAP_EXTRACT_RESULT_TPL``` - Handlebars template to be used to present matching information to the user (can use helpers from npm handlebards-helpers package + 'any' helper )
- ```LDAP_EXTRACT_TLSMODE``` - plain|starttls|tls remember to provide the CA cert if you set this to starttls or tls. If you set this to tls, also make sure to use ldaps:// as the protocol in LDAP_URL
- ```LDAP_EXTRACT_CA_CERT``` - CA cert when using tls|starttls
- ```LDAP_EXTRACT_LISTENING_TRIGGER``` - the keyword to listen to in hubot conversations (can also be set to be a regular expression, e.g. ```(directory|info|ldap|contact)```, default: ```ldap```)
- ```LDAP_EXTRACT_MAXRESULTS``` - max. no of result items returned (default: 5)

### Response template

The template used to render entries matching a given search query is defined in ```LDAP_EXTRACT_RESULT_TPL``` and must contain a [Handlebars](http://handlebarsjs.com/) template. In addition to the built-in helpers, helpers from the [handlebars-helpers](https://www.npmjs.com/package/handlebars-helpers) as well as the [any](https://www.npmjs.com/package/any) packages are also available. This allows conveniently applying different responses for each matching entry, based on its individual attributes.

#### Using the _any_ helper

The _any_ helper is being used as a block expression:

```
{{#any [1,2,3] 3}}
    {{../permalink}}
{{/any}}
```

#### Example template

```
{{#contains objectClass "employee"}}
  *{{displayName}}*
    {{#if accountActive}}  
      {{title}}
      {{ou}} ({{l}})
      {{mail}}
      {{telephoneNumber}}
      {{#if mobile}}{{mobile}}{{/if}}
    {{else}}
      _Inactive user - contact HR for contact information_
    {{/if}}
{{/contains}}    
{{#contains objectClass "external"}}
    {{#unless accountActive}}_Inactive user_{{/unless}}
    {{employeeType}}
    {{svTeam}}
    {{mail}}
    {{telephoneNumber}}
    {{#if mobile}}{{mobile}}{{/if}}
    {{#if street}}
      {{street}}
      {{postalCode}} {{l}}
    {{/if}}
{{/contains}}
```


## Usage

```hubot ldap <searchquery>```, where _ldap_ could be overridden in you particular case via ```LDAP_EXTRACT_LISTENING_TRIGGER```
