module PSSE2PAN

export psse_raw_to_pan, print_load, print_line, print_transformer, print_generator

using Printf: @printf
import PowerModels


function print_bus(bus; io::IO=stdout)
    number = bus["index"]
    name = "bus_" * string(number)
    base_kv = bus["base_kv"]
    v0 = bus["vm"]
    theta0 = rad2deg(bus["va"])
    @printf(io, "%s bus%d powerbus vb=%.6e v0=%.6e theta0=%.6e\n", name, number, base_kv*1e3, v0, theta0);
end


function print_load(load::AbstractDict; base_MVA::Number, bus_base_kv::AbstractDict,
        io::IO=stdout, print_out_of_service::Bool=false)
    if load["status"] == 1 || print_out_of_service
        name = "load_" * string(load["index"]);
        bus = load["load_bus"]
        pc, qc = load["pd"], load["qd"]
        @printf(io, "%s bus%d powerload utype=0 pc=%.6e qc=%.6e prating=%.6e vrating=%.6e\n",
            name, bus, pc, qc, base_MVA*1e6, bus_base_kv[bus]*1e3)
    end
end


function print_line(line::AbstractDict; base_MVA::Number, bus_base_kv::AbstractDict,
        io::IO=stdout, print_out_of_service::Bool=false)
    if line["transformer"]
        throw(ArgumentError("Branch is a transformer"));
    end
    if line["br_status"] == 1 || print_out_of_service
        from_bus, to_bus, cnt = map(x -> x isa Int ? x : parse(Int64, x), line["source_id"][2:4])
        name = "line_" * string(from_bus) * "_" * string(to_bus) * "_" * string(cnt);
        r, x, b = line["br_r"], line["br_x"], line["b_fr"]
        @printf(io, "%s bus%d bus%d powerline utype=0 r=%.6e x=%.6e b=%.6e prating=%.6e vrating=%.6e\n",
            name, from_bus, to_bus, r, x, b, base_MVA*1e6, bus_base_kv[from_bus]*1e3)
    end
end


function print_transformer(trans::AbstractDict; base_MVA::Number, bus_base_kv::AbstractDict,
        io::IO=stdout, print_out_of_service::Bool=false)
    if ! trans["transformer"]
        throw(ArgumentError("Branch is not a transformer"));
    end
    if trans["br_status"] == 1 || print_out_of_service
        from_bus, to_bus, cnt = map(x -> x isa Int ? x : parse(Int64, x), trans["source_id"][[2,3,5]]);
        name = "trans_" * string(from_bus) * "_" * string(to_bus) * "_" * string(cnt);
        r, x = trans["br_r"], trans["br_x"]
        base_kv_prim, base_kv_sec = bus_base_kv[to_bus], bus_base_kv[from_bus]
        @printf(io, "%s bus%d bus%d powertransformer r=%.6e x=%.6e a=%.6e kt=1 prating=%.6e vrating=%.6e\n",
            name, to_bus, from_bus, r, x, base_kv_sec/base_kv_prim, base_MVA*1e6, base_kv_prim*1e3)
    end
end


function print_generator(gen::AbstractDict; gen_type::Integer, base_MVA::Number, bus_base_kv::AbstractDict,
        io::IO=stdout, print_out_of_service::Bool=false)
    if gen["gen_status"] == 1 || print_out_of_service
        bus = gen["gen_bus"];
        group = parse(Int64, gen["source_id"][3]);
        name = "gen_" * string(bus) * "_" * string(group)
        vg = gen["vg"]
        prating = gen["mbase"]
        pg, qg = gen["pg"] / prating * base_MVA, gen["qg"] / prating * base_MVA
        R, X = gen["zr"], gen["zx"]
        @printf(io, "%s bus%d powergenerator type=%d prating=%.6e pg=%.6e qg=%.6e vrating=%.6e vg=%.6e ra=%g xdp=%g\n",
            name, bus, gen_type, prating*1e6, pg, qg, bus_base_kv[bus]*1e3, vg, R, X)
    end
end


function psse_raw_to_pan(raw_file::AbstractString, pan_file::AbstractString; slack::Integer=-1)
    network = PowerModels.parse_file(raw_file, import_all=true);
    base_MVA = network["baseMVA"];
    bus_base_kv = Dict(bus["bus_i"] => bus["base_kv"] for bus in values(network["bus"]));

    open(pan_file, "w") do io
        # Buses
        for bus in values(network["bus"])
            print_bus(bus; io=io);
        end
        # Loads
        for load in values(network["load"])
            print_load(load; base_MVA=base_MVA, bus_base_kv=bus_base_kv, io=io);
        end
        # Lines
        for branch in values(network["branch"])
            if ! branch["transformer"]
                print_line(branch; base_MVA=base_MVA, bus_base_kv=bus_base_kv, io=io);
            end
        end
        # Transformers
        for branch in values(network["branch"])
            if branch["transformer"]
                print_transformer(branch; base_MVA=base_MVA, bus_base_kv=bus_base_kv, io=io);
            end
        end
        # Generators
        for gen in values(network["gen"])
            print_generator(gen; gen_type=2, base_MVA=base_MVA, bus_base_kv=bus_base_kv, io=io)
        end
    end
    true
end

end
