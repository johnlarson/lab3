ruleset gossip {

	meta {
		name "Gossip"
	}

	global {

		__testing = {
			"queries": [
				{
					"name": "getPeer",
					"args": ["state"]
				},
				{
					"name": "preparedMessage",
					"args": ["state", "subscriber"]
				}
			],
			"events": [
				{
					"domain": "gossip",
					"type": "heartbeat",
					"args": []
				},
				{
					"domain": "gossip",
					"type": "rumor",
					"args": [
						"MessageID",
						"SensorID",
						"Temperature",
						"Timestamp"
					]
				},
				{
					"domain": "gossip",
					"type": "add_subscription",
					"args": ["wellknown_Tx", "Tx_host"]
				}
			]
		}

		getPeer = function(state) {

		}

		getNextSequenceNumber = function() {
			id = meta:picoId;
			ent:known{[id, id]} => maxSelfKnown(id) + 1 | 0
		}

		maxSelfKnown = function(id) {
			idx = index(null);
			idx == -1 => ent:rumors{meta:picoId}.length - 1 | idx
		}

		preparedMessage = function(state, subscriber) {

		}

		send = defaction(subscriber, m) {
			send_directive("null", {})
		}

		update = defaction(state) {
			send_directive("null", {})
		}

	}

	rule start_gossiping {
		select when wrangler ruleset_added where rids >< meta:rid
		fired {
			raise gossip event "heartbeat"
		}
	}

	rule gossip {
		select when gossip heartbeat
	}

	rule receive_rumor {
		select when gossip rumor
		pre {

			mid = event:attr("messageId")
			parts = mid.split(":")
			id = parts[0]
			seq = parts[1]
			me = meta:picoId
		}
		fired {
			ent:rumors := ent:rumors.defaultsTo({});
			ent:rumors{id} := ent:rumors{id}.defaultsTo([]);
			ent:rumors{[id, seq]} := event:attrs;
			ent:known := ent:known.defaultsTo({});
			ent:known{me} := ent:known{me}.defaultsTo({});
			ent:known{[me, id]} := maxSelfKnown(id)
		}
	}

	rule receive_seen {
		select when gossip seen

	}

	rule add_subscription {
		select when gossip add_subscription
	}

	rule record_own_temp {
		select when wovyn new_temperature_reading
		pre {
			id = meta:picoId
			seq = getNextSequenceNumber()
		}
		fired {
			raise gossip event "rumor"
				attributes {
					"MessageID": <<#{id}:#{seq}>>,
					"SensorID": id,
					"Temperature": event:attr("temperature"),
					"Timestamp": event:attr("timestamp")
				}
		}
	}

}