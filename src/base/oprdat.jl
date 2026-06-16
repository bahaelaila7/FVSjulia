# oprdat.jl — OPRDAT: read activities from an external file and add to schedule
# Translated from: oprdat.f (87 lines)

function OPRDAT(jexopt::Integer, kode_ref::Ref{Int32})
    kode_ref[] = Int32(-999)
    if jexopt <= 0; return nothing; end

    io_r = get(io_units, Int32(jexopt), nothing)
    if isnothing(io_r); return nothing; end

    ipass = 0
    nadd  = 0
    nfail = 0

    @label label_10
    # Read a line; END → label_30
    line = ""
    try
        line = readline(io_r)
    catch
        @goto label_30
    end
    if eof(io_r) && isempty(line); @goto label_30; end

    if strip(line) == strip(NPLT)
        @label label_15
        try
            line = readline(io_r)
        catch
            @goto label_30
        end
        if eof(io_r) && isempty(line); @goto label_30; end

        if line[1:min(3, length(line))] != "End"
            # Parse: iactk, idt, nprms, prms...
            parts = split(strip(line))
            if length(parts) >= 3
                iactk_v = parse(Int32, parts[1])
                idt_v   = parse(Int32, parts[2])
                nprms_v = parse(Int32, parts[3])
                prms_v  = zeros(Float32, max(1, Int(nprms_v)))
                for pi in 1:min(Int(nprms_v), length(parts)-3)
                    prms_v[pi] = parse(Float32, parts[3+pi])
                end
                if idt_v >= IY[Int(ICYC)]
                    kode2 = Ref(Int32(0))
                    OPADD(idt_v, iactk_v, Int32(0), nprms_v, prms_v, kode2)
                    if kode2[] == 0
                        nadd += 1
                    else
                        nfail += 1
                    end
                end
            end
            @goto label_15
        end
        if nadd > 0
            OPINCR(IY, ICYC, NCYC)
        end
        kode_ref[] = nfail == 0 ? Int32(nadd) : Int32(-nfail)
        return nothing
    else
        @label label_20
        try
            line = readline(io_r)
        catch
            @goto label_30
        end
        if eof(io_r) && isempty(line); @goto label_30; end
        if line[1:min(3, length(line))] != "End"; @goto label_20; end
        @goto label_10
    end

    @label label_30
    seekstart(io_r)

    if ipass == 1; return nothing; end
    ipass = 1
    @goto label_10
end
