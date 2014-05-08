# require 'newrelic'
Firebase = require 'firebase'
winston = require 'winston'
http = require 'http'
Squeegee = require 'squeegee'

if process.env.NODE_ENV is 'production'
	# Use the production firebase and creds
	firebaseURL = 'http://boomerangrang.firebaseio.com'

else
	# Use the development firebase
	firebaseURL = 'http://boomerangrang.firebaseio.com' 

# Class for crawler
class Crawler

	constructor: (@rootRef, snapshot) ->
		@link = snapshot.val()
		@ref = snapshot.ref()

		# Create a new client
		@client = new Squeegee @link.url

		# console.log @client.url

		@client.on 'error', (err) =>
			console.log 'error fetching'
			console.log err
			@deleteRef()

		@client.on 'parse', @parsed

		# Actually start the fetch
		@client.fetch()

	parsed: =>
		console.log 'parsed!'
		console.log @client.title
		console.log @client.description
		console.log @client.image
		console.log @client.icon
		# Set each of the firebase props, if they exist
		linkRef = @rootRef.child "users/#{@link.user}/links/#{@link.id}"
		if @client.title
			linkRef.child('title').set @client.title
		if @client.description
			linkRef.child('description').set @client.description
		if @client.image
			linkRef.child('image').set @client.image
		if @client.icon
			linkRef.child('icon').set @client.icon

		# Remove the link from the queue
		@deleteRef()

		console.log '\n---------------------------------\n'

	deleteRef: ->
		# Removes the item from the queue
		@ref.remove()



# Connect to the firebase
@rootRef = new Firebase firebaseURL

# Listen for links added to the queue
@queueRef = @rootRef.child 'linkQueue'
@queueRef.on 'child_added', (snapshot) =>
	console.log 'item added!'

	# Create a new crawler to fetch this page
	new Crawler @rootRef, snapshot
	


# Create a little http server to respond to uptime requests
server = http.createServer (req, res) ->
	res.writeHead 200, 
		'Content-Type': 'text/plain'
	res.end 'The boomerang server is up!'
server.listen process.env.PORT