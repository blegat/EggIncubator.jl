const url_base = "https://www.rika-firenet.com"
const url_login = "/web/login"
const url_stove = "/web/stove/"
const url_api = "/api/client/"

struct Login
    email::String
    password::String
end

function stove_id(rika::Login; kws...)
    body = String(HTTP.post(url_base * url_login, body = Dict("email" => rika.email, "password" => rika.password); kws...).body)
    html = Gumbo.parsehtml(body)
    stove = html.root.children[2].children[1].children[4].children[1].children[2].children[1].children[1].attributes["href"]
    return split(stove, '/')[end]
end

function temperature(rika::Login; kws...)
    id = stove_id(rika; kws...)
    body = String(HTTP.get(url_base * url_api * "$id/status"; kws...).body)
    return parse(Float64, JSON.parse(body)["sensors"]["inputRoomTemperature"])
end

function old_temperature()
    body = String(HTTP.get(stove).body)
    html = Gumbo.parsehtml(body)
    return html.root.children[2].children[1].children[4].children[2].children[3].children[1].children[3].children[1].children[1].children[1]
end
