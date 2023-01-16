module KeywordStrings

import Base: string, repeat, *, ^, %

export @kw_str, repeat, *, ^, %

struct KeywordStringsError
    msg::String
end

struct NullInterpolation
    tk::Symbol
end

struct KeywordString
    _tokens::Vector{Union{Symbol, String}}
    _interpolate_later::Dict{Symbol, NullInterpolation}
    function KeywordString(_parsed_args)
        _tokens = Vector{Union{Symbol, String}}()
        _interpolate_later = Dict{Symbol, NullInterpolation}()
        for tk in _parsed_args
            if isa(tk, Symbol)
                _interpolate_later[tk] = NullInterpolation(tk)
                push!(_tokens, tk)
            else
                push!(_tokens, string(tk))
            end
        end
        new(_tokens, _interpolate_later)
    end

    function KeywordString(_tokens, _interpolate_later)
        new(_tokens, _interpolate_later)
    end
end
KeywordString(kws::KeywordString) = KeywordString(copy(kws._tokens), copy(kws._interpolate_later))

macro kw_str(str)
    quote let
        interpolate_locals = endswith($(str), "\$!")
        interpolate_module = endswith($(str), "\$¡")
        interpolate_asmuch = endswith($(str), "\$:")

        _s = if interpolate_locals || interpolate_module || interpolate_asmuch
            chop($(str); tail=2)
        else
            $(str)
        end
    
        _s = "\""*_s*"\""
        _p = Meta.parse(_s)

        if typeof(_p) <: String
            _p
        else
            kws = KeywordString(_p.args)
            if interpolate_locals
                kws % Base.@locals()
            elseif interpolate_module
                kws % @__MODULE__
            else
                kws % Base.@locals() % @__MODULE__
            end
        end end
    end
end

string(nullinterpolation::NullInterpolation) = throw(KeywordStringsError("Symbol :$(nullinterpolation.tk) not defined. Make sure that all KeywordString objects have been formatted."))
string(kws::KeywordString) = join(string(get(kws._interpolate_later, tk, tk)) for tk in kws._tokens)

_has_fmt_val(fmt, tk::Symbol) = hasproperty(fmt, tk) || (hasmethod(haskey, Tuple{typeof(fmt), Symbol}) && haskey(fmt, tk))

function _get_fmt_val(fmt, tk::Symbol)
    errmsg = "Tried to access a format key or property :$tk from type $(typeof(fmt)) but this key or property could not be accessed."
    if hasmethod(haskey, Tuple{typeof(fmt), Symbol}) && haskey(fmt, tk)
        retrieved_key = get(fmt, tk) do
            throw(KeywordStringsError(errmsg))
        end
        if hasproperty(fmt, tk)
            retrieved_property = getproperty(fmt, tk)
            if !isequal(retrieved_key, retrieved_property)
                throw(KeywordStringsError("Formatting is ambiguous; formatter of type $(typeof(fmt)) has :$tk as both a key and a property but with inequal values."))
            end
        end
        return retrieved_key
    end
    if hasproperty(fmt, tk)
        return getproperty(fmt, tk)
    end
    throw(KeywordStringsError(errmsg))
end

function _format!(kws::KeywordString, fmt)
    for (idx, tk) ∈ pairs(kws._tokens)
        if isa(tk, Symbol)
            !(_has_fmt_val(fmt, tk)) && continue
            kws._tokens[idx] = string(_get_fmt_val(fmt, tk))
            delete!(kws._interpolate_later, tk)
        end
    end
end
function format(_kws::KeywordString, fmt)
    kws = KeywordString(_kws) # non-mutating operator
    _format!(kws, fmt)
    if length(kws._interpolate_later) |> iszero
        return string(kws)
    else
        return kws
    end
end

function mul!(kws::KeywordString, s)
    push!(kws._tokens, convert(String, s))
end
function mul!(s, kws::KeywordString)
    pushfirst!(kws._tokens, convert(String, s))
end
function mul!(kws_1::KeywordString, kws_2::KeywordString)
    append!(kws_1._tokens, kws_2._tokens)
    merge!(kws_1._interpolate_later, kws_2._interpolate_later)
end

function mul(_kws::KeywordString, s)
    kws = KeywordString(_kws)
    mul!(kws, s)
    return kws
end
function mul(s, _kws::KeywordString)
    kws = KeywordString(_kws)
    mul!(s, kws)
    return kws
end
function mul(_kws_1::KeywordString, kws_2::KeywordString)
    kws_1 = KeywordString(_kws_1)
    mul!(kws_1, kws_2)
    return kws_1
end

Broadcast.broadcastable(kws::KeywordString) = Ref(kws)

%(kws::KeywordString, fmt) = format(kws, fmt)
%(fmt, kws::KeywordString) = format(kws, fmt)

*(kws::KeywordString, s) = mul(kws, s)
*(s, kws::KeywordString) = mul(s, kws)
*(kws_1::KeywordString, kws_2::KeywordString) = mul(kws_1, kws_2)

repeat(kws::KeywordString, n::T) where {T <: Integer} = reduce(*, repeat([kws], n))
^(kws::KeywordString, n::T) where {T <: Integer} = repeat(kws, n)

end