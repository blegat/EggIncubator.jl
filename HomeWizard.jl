struct Socket
    ip_address
end

const POWER = "power_on"

url(s::Socket) = string("http://", s.ip_address, "/api/v1/")

function set_state(s::Socket, field, value)
    return HTTP.put(string(url(s), "state"); body="{\"$field\": $value}")
end

power_on(s::Socket) = set_state(s, POWER, true)
power_off(s::Socket) = set_state(s, POWER, false)

function state(s::Socket)
    return HTTP.get(string(url(s), "state"))
end

function data(s::Socket)
    return HTTP.get(string(url(s), "state"))
end

function powered(s::Socket)
    body = String(state(S).body)
    parsed = JSON.parse(body)
    return parsed[POWER]
end

