const url_base = "https://www.rika-firenet.com"
const url_login = "/web/login"
const url_stove = "/web/stove/"
const url_api = "/api/client/"

function warn_error(f)
    ret = nothing
    try
        ret = f(nothing)
    catch err
        @warn("Got exception $(typeof(err)), let's hope it goes better next time")
        Base.showerror(Base.stderr, err)
        println(Base.stderr)
    end
    return ret
end

struct Login
    email::String
    password::String
end

struct Stove
    id::String
end

function connect(rika::Login; kws...)
    body = String(HTTP.post(url_base * url_login, body = Dict("email" => rika.email, "password" => rika.password); kws...).body)
    html = Gumbo.parsehtml(body)
    a = html.root.children[2].children[1].children[4].children[1]
    if length(a.children) < 2
        error("Incorrect email/password combination")
    end
    stove = a.children[2].children[1].children[1].attributes["href"]
    return Stove(split(stove, '/')[end])
end

function _read(file)
    lines = readlines(file)
    if length(lines) > 1
        @warn("There are more than one lines in the file `$file`")
    end
    if isempty(lines[1])
        error("The file `$file` is empty")
    end
    return first(lines)
end

function connect(; kws...)
    email = _read("email")
    password = _read("password")
    return connect(Login(email, password); kws...)
end

function temperature(rika::Stove; kws...)
    T = warn_error() do ()
        body = String(HTTP.get(url_base * url_api * "$(rika.id)/status"; kws...).body)
        return parse(Float64, JSON.parse(body)["sensors"]["inputRoomTemperature"])
    end
    if isnothing(T)
        @warn("The attempt for getting the temperature failed, I will try reconnecting to `rika` now, maybe the `id` changed")
        old_rika = rika
        rika = connect(; kws...)
        if rika != old_rika
            @warn("The stove id had indeed changed from $(old_rika.id) to $(rika.id), it's good we reconnected, it should go better next time")
        else
            @warn("The stove id ($(rika.id)) doesn't seem to have changed, it might have just been a network issue, let's hope it works better next time")
        end
        return T, rika
    else
        return T, rika
    end
end

function old_temperature()
    body = String(HTTP.get(stove).body)
    html = Gumbo.parsehtml(body)
    return html.root.children[2].children[1].children[4].children[2].children[3].children[1].children[3].children[1].children[1].children[1]
end
