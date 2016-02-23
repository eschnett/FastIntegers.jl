module FastIntegers

typealias IntTypes Union{Int8, Int16, Int32, Int64, Int128}
typealias UIntTypes Union{UInt8, UInt16, UInt32, UInt64, UInt128}
typealias IntegerTypes Union{IntTypes, UIntTypes}



# export checked_abs
#
# checked_abs{T<:IntTypes}(x::T) =
#     Base.llvmcall("""
#         %ret = checked.abs %1
#         return int %ret
#         """, T, Tuple{T}, x)
#
# checked_abs{T<:UIntTypes}(x::T) = x



# LLVM seems to ignore this
export fast_assert
function fast_assert(cond::Bool)
    Base.llvmcall("""
        br i1 %0, label %good, label %bad
    good:
        ret void
    bad:
        unreachable
    """, Void, Tuple{Bool}, cond)
end
@generated function fast_assert{T<:IntegerTypes}(x::T, cond::Bool)
    tp = "i$(8*sizeof(T))"
    quote
        Base.llvmcall("""
            br i1 %1, label %good, label %bad
        good:
            ret $($tp) %0
        bad:
            unreachable
        """, T, Tuple{T, Bool}, x, cond)
    end
end

# This leads to segfaults in LLVM
#=
export fast_assume
@generated function fast_assume{T<:IntegerTypes}(x::T, cond::Bool)
    tp = "i$(8*sizeof(T))"
    quote
        Base.llvmcall("""
            br i1 %1, label %good, label %bad
        good:
            ret $($tp) %0
        bad:
            ret $($tp) undef
        """, T, Tuple{T, Bool}, x, cond)
    end
end
=#



export fast_pos
fast_pos{T<:IntegerTypes}(x::T) = x

export fast_neg
fast_neg{T<:IntegerTypes}(x::T) = T(0) - x

export fast_abs
function fast_abs{T<:IntTypes}(x::T)
    # Note: -x = ~(x-1)
    m = -signbit(x)
    r = (x + m) $ m
    # fast_assert(r >= T(0))
    # r = fast_assert(r, r >= T(0))
    # r = fast_assume(r, r >= T(0))
    r
end
fast_abs{T<:UIntTypes}(x::T) = x

export fast_add
@generated function fast_add{T<:IntegerTypes}(x::T, y::T)
    tp = "i$(8*sizeof(T))"
    nw = T <: IntTypes ? "nsw" : "nuw"
    quote
        Base.llvmcall("""
            %res = add $($nw) $($tp) %0, %1
            ret $($tp) %res
        """, T, Tuple{T, T}, x, y)
    end
end

export fast_sub
@generated function fast_sub{T<:IntegerTypes}(x::T, y::T)
    tp = "i$(8*sizeof(T))"
    nw = T <: IntTypes ? "nsw" : "nuw"
    quote
        Base.llvmcall("""
            %res = sub $($nw) $($tp) %0, %1
            ret $($tp) %res
        """, T, Tuple{T, T}, x, y)
    end
end

export fast_mul
@generated function fast_mul{T<:IntegerTypes}(x::T, y::T)
    tp = "i$(8*sizeof(T))"
    nw = T <: IntTypes ? "nsw" : "nuw"
    quote
        Base.llvmcall("""
            %res = mul $($nw) $($tp) %0, %1
            ret $($tp) %res
        """, T, Tuple{T, T}, x, y)
    end
end

export fast_div
@generated function fast_div{T<:IntegerTypes}(x::T, y::T)
    tp = "i$(8*sizeof(T))"
    div = T <: IntTypes ? "sdiv" : "udiv"
    quote
        Base.llvmcall("""
            %res = $($div) $($tp) %0, %1
            ret $($tp) %res
        """, T, Tuple{T, T}, x, y)
    end
end

export fast_rem
@generated function fast_rem{T<:IntegerTypes}(x::T, y::T)
    tp = "i$(8*sizeof(T))"
    rem = T <: IntTypes ? "srem" : "urem"
    quote
        Base.llvmcall("""
            %res = $($rem) $($tp) %0, %1
            ret $($tp) %res
        """, T, Tuple{T, T}, x, y)
    end
end

export fast_fld
function fast_fld{T<:IntTypes}(x::T, y::T)
    # fld(x,y) = div(x,y) - ((x>=0) != (y>=0) && rem(x,y) != 0 ? 1 : 0)
    d = fast_div(x, y)
    d - (signbit(x $ y) & (d * y != x))
end
fast_fld{T<:UIntTypes}(x::T, y::T) = fast_div(x, y)

export fast_mod
function fast_mod{T<:IntTypes}(x::T, y::T)
    # x = fld(x,y)*y + mod(x,y)
    x - fast_fld(x, y) * y
end
fast_mod{T<:UIntTypes}(x::T, y::T) = fast_rem(x, y)

export fast_cld
function fast_cld{T<:IntTypes}(x::T, y::T)
    # cld(x,y) = div(x,y) + ((x>0) = (y>0) && rem(x,y) != 0 ? 1 : 0)
    d = fast_div(x, y)
    d + (((x > 0) == (y > 0)) & (d * y != x))
end
function fast_cld{T<:UIntTypes}(x::T, y::T)
    d = fast_div(x, y)
    d + (d * y != x)
end

end
