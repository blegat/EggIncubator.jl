struct Socket
    ip_address
end

const POWER = "power_on"

url(s::Socket) = string("http://", s.ip_address, "/api/v1/")

function set_state(s::Socket, field, value; kws...)
    return HTTP.put(string(url(s), "state"); body="{\"$field\": $value}", kws...)
end

power_on(s::Socket; kws...) = set_state(s, POWER, true; kws...)
power_off(s::Socket; kws...) = set_state(s, POWER, false; kws...)

function state(s::Socket; kws...)
    return HTTP.get(string(url(s), "state"); kws...)
end

function data(s::Socket; kws...)
    return HTTP.get(string(url(s), "state"); kws...)
end

function powered(s::Socket; kws...)
    body = String(state(s; kws...).body)
    parsed = JSON.parse(body)
    return parsed[POWER]
end

