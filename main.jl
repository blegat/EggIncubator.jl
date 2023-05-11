import HTTP
import JSON
import Gumbo
import Dates

include("HomeWizard.jl")
include("RikaFireNet.jl")

function enforce_lamp_power(on, home_wizard; color, kws...)
    desired = on ? "on" : "off"
    not_desired = on ? "off" : "on"
    if isnothing(home_wizard)
        println("\007")
        @warn("  HomeWizard is disabled, turn it $desired manually in the \"Now\" tab of the mobile app")
    else
        printstyled("  connecting to HomeWizard socket...\n"; color)
        if powered(home_wizard; kws...) != on
            printstyled("  Lamp is $not_desired so turning it $desired\n"; color)
            set_state(home_wizard, POWER, on; kws...)
            printstyled("  Lamp is now $desired\n"; color)
        else
            printstyled("  Lamp is already $desired so it's only inertia\n"; color)
        end
    end
end

function colorT(minT, maxT, T)
    if T < minT
        return :blue
    elseif T > maxT
        return :red
    else
        return :green
    end
end

function update(minT, maxT, rika, home_wizard; kws...)
    T = temperature(rika; kws...)
    color = colorT(minT, maxT, T)
    printstyled("$(Dates.now()) Current temperature is $(T)°C\n"; color)
    if T < minT
        printstyled("  $(T)°C is colder than $(minT)°C\n"; color)
        enforce_lamp_power(true, home_wizard; color, kws...)
    elseif T > maxT
        printstyled("  $(T)°C is hotter than $(maxT)°C\n"; color)
        enforce_lamp_power(false, home_wizard; color, kws...)
    end
    return
end

# The default `readtimeout` is `0` which means there is no timeout.
# It's a bit dangerous for the egg incubator to be stuck waiting so
# let's use a timeout of 10 seconds which is the default value for
# `connect_timeout`.
function main(minT, maxT, Δt, rika, home_wizard; readtimeout=10)
    while true
        try
            update(minT, maxT, rika, home_wizard; readtimeout)
        catch err
            if err isa InterruptException
                @warn("Interrupted, stopping now")
            else
                @warn("Got exception $(typeof(err)), let's hope it goes better next time")
                Base.showerror(Base.stderr, err)
                println(Base.stderr)
            end
        end
        sleep(Δt)
    end
end
