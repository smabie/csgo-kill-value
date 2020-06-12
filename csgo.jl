using Plots
using StatsKit
using DataFrames
using CSV
using Printf

df = DataFrame()
append!(df, DataFrame(CSV.File("esea_meta_demos.part1.csv")))
append!(df, DataFrame(CSV.File("esea_meta_demos.part2.csv")))
df = df[:, [:file, :round, :winner_side]]

df2 = DataFrame()
append!(df2, DataFrame(CSV.File("esea_master_kills_demos.part1.csv")))
append!(df2, DataFrame(CSV.File("esea_master_kills_demos.part2.csv")))
df2 = df2[:, [:file, :round, :ct_alive, :t_alive]]

df = join(df, df2, kind = :inner, on = [:file, :round])

xs = unique(df[:, [:file, :round, :winner_side]])
xs.ct_alive = 5
xs.t_alive = 5

df = sort(vcat(df, xs))

windf = map(1:5) do x
    xs = filter(r -> r[:ct_alive] == x && r[:t_alive] == x, df)
    ntrials = length(xs.winner_side)
    twins = sum(xs.winner_side .== "Terrorist")
    ctwins = ntrials-twins
    (ctwins/ntrials, cdf(Binomial(ntrials), ctwins))
end |> DataFrame

DataFrames.rename!(windf, :1 => :ct_win_rate)
DataFrames.rename!(windf, :2 => :p_value)
windf[:players] = collect(1:5)

plot(windf[:ct_win_rate],
     xlabel="players on each side", ylabel="ct win probability",
     label=nothing, xflip=true, yformatter=(x -> @sprintf "%.0f%%" (100*x)),
     size=(900, 600))
savefig("evencs.png")

print(windf)

tdf = map(1:5) do nct
    Symbol(@sprintf "%dct_alive" nct) => map(0:5) do x
        xs = filter(r -> r[:ct_alive] == nct && r[:t_alive] == x, df)
        sum(xs.winner_side .== "CounterTerrorist")/length(xs.winner_side)
    end
end |> DataFrame
tdf[:t_alive] = 0:5

print(tdf)

plot(0:5, tdf[Symbol("5ct_alive")], label="5 ct alive",
      legend=:topleft, yformatter=(x -> @sprintf "%.0f%%" (100*x)),
      xflip=true, xlabel="t alive", ylabel="ct win probability", size=(900, 600))
plot!(0:5, tdf[Symbol("4ct_alive")], label="4 ct alive")
plot!(0:5, tdf[Symbol("3ct_alive")], label="3 ct alive")
plot!(0:5, tdf[Symbol("2ct_alive")], label="2 ct alive")
plot!(0:5, tdf[Symbol("1ct_alive")], label="1 ct alive")
savefig("csperm.png")
