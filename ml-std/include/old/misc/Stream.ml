
"=== mlcpp: BEGIN include/std/loops.mlp ======================================="

var while (cond, do):{
    var loop _
    loop := ():{
        cond() && {
            do()
            _ := loop()
        }
        ;
    }
    loop()
}

var until (cond, do):{
    var loop _
    loop := ():{
        cond() || {
            do()
            _ := loop()
        }
        ;
    }
    loop()
}

var do_while (do, cond):{
    do()
    while(cond, do)
}

var do_until (do, cond):{
    do()
    until(cond, do)
}

var foreach (OUT container, fn):{
    var nth 1
    until(():{nth > len(container)}, ():{
        fn(&container[#nth])
        nth += 1
    })
    container
}

"=== mlcpp: END include/std/loops.mlp (finally back to include/misc/Stream.mlp) ==="
"=== mlcpp: BEGIN include/std/LazyList.mlp ===================================="

"=== mlcpp: BEGIN include/std/cond.mlp ========================================"

var tern (cond, if_true, if_false):{
    var res _
    cond && {res := if_true}
    cond || {res := if_false}
    res
}

var !tern (cond, if_false, if_true):{
    tern(cond, if_true, if_false)
}

var not (bool):{
    tern(bool, $false, $true)
}

"=== mlcpp: END include/std/cond.mlp (back to include/std/LazyList.mlp) ======="
"=== mlcpp: BEGIN include/std/Optional.mlp ===================================="



var Optional (some?, val):{
    var none? ():{
        not(some?)
    }

    var some ():{
        some? || {
            die("calling some() on empty Optional")
        }
        val
    }

    var dispatcher (op):{
        tern(op == 'none?, none?, {
            tern(op == 'some, some, {
                die("unknown Optional operation: `" + op + "`")
            })
        })
    }
    dispatcher
}

var none? (opt):{
    opt('none?)()
}

var some (opt):{
    opt('some)()
}

"=== mlcpp: END include/std/Optional.mlp (back to include/std/LazyList.mlp) ==="

"=== PAIR ============================="

var Pair (left, right):{
    var selector (op):{
        tern(op == 'left, left, {
            tern(op == 'right, right, {
                die("unknown Pair operation: `" + op + "`")
            })
        })
    }
    selector
}

var left (pair):{
    pair('left)
}

var right (pair):{
    pair('right)
}

"=== LAZYLIST ========================="

var Pair? (left, right):{
    Optional($true, Pair(left, right))
}

var END {
    Optional($false, _)
}

var LazyList {
    var LazyList-1+ _

    var LazyList (xs...):{
        tern($#varargs == 0, END, {
            LazyList-1+(xs...)
        })
    }

    LazyList-1+ := (x, xs...):{
        Pair?(x, LazyList(xs...))
    }

    LazyList
}

"=== mlcpp: END include/std/LazyList.mlp (finally back to include/misc/Stream.mlp) ==="
"=== mlcpp: BEGIN include/std/functional.mlp =================================="



"=== mlcpp: BEGIN include/std/Iterator.mlp ===================================="







var Some (x):{
    Optional($true, x)
}

var Iterator (subscriptable):{
    var Iterator (container):{
        container
        var nth 1
        var next (peek?):{
            tern(nth > len(container), END, {
                var res container[#nth]
                peek? || {nth += 1}
                Some(res)
            })
        }
        next
    }

    var Iterator::fromStream (stream):{
        stream
        var next (peek?):{
            tern(none?(stream), END, {
                var res left(some(stream))
                peek? || {
                    stream := right(some(stream))
                }
                Some(res)
            })
        }
        next
    }

    var lambda? (x):{
        var < (lhs, rhs):{
            not(lhs > rhs || lhs == rhs)
        }
        Str(x) == "<lambda>" && len(x) < 8
    }

    var next {
        !tern(lambda?(subscriptable), Iterator(subscriptable), {
            Iterator::fromStream(subscriptable)
        })
    }

    var dispatcher (op):{
        tern(op == 'next, ():{next(0)}, {
            tern(op == 'peek, ():{next(1)}, {
                die("unknown iterator operation: `" + op + "`")
            })
        })
    }
    dispatcher
}

var ArgIterator (args...):{
    Iterator(LazyList(args...))
}

var SeqIterator (init, stop?, update):{
    let curr init

    var peek ():{
        Some(curr)
    }

    var next _
    next := ():{
        peek := ():{
            tern(stop?(curr), END, Some(curr))
        }
        next := ():{
            tern(stop?(curr), END, {
                update(&curr)
                Some(curr)
            })
        }
        Some(curr)
    }

    var dispatcher (op):{
        tern(op == 'peek, peek, {
            tern(op == 'next, next, {
                die("unknown SeqIterator operation: `" + op + "`")
            })
        })
    }
    dispatcher
}

var RangeIterator<= (from, to):{
    {
        "accepts as input Int, Char or Str"
        var str? (x):{
            len(Str(x + 0)) > len(Str(x))
        }
        var charInputs? {
            var charInputs? $true
            charInputs? &&= str?(from) && len(from) == 1
            charInputs? &&= str?(to) && len(to) == 1
            charInputs?
        }
        from := tern(charInputs?, Char, Int)(from)
        to := tern(charInputs?, Char, Int)(to)
    }
    var >= (a, b):{
        a > b || a == b
    }
    var RangeIterator<= {
        var i from
        var stop? (i):{i >= to}
        var update (i):{i += 1}
        SeqIterator(i, stop?, update)
    }
    RangeIterator<=
}

var peek (iterator):{
    iterator('peek)()
}

var next (iterator):{
    iterator('next)()
}

-- augment foreach() from loops.mlp
{
    var Container::foreach foreach

    foreach := (OUT iterable, fn):{
        var Iterator::foreach (iterator, fn):{
            var curr next(iterator)
            until(():{none?(curr)}, ():{
                fn(some(curr))
                curr := next(iterator)
            })
        }

        var < (a, b):{
            (a > b || a == b) == $false
        }
        var lambda? (x):{
            Str(x) == "<lambda>" && len(x) < 8
        }
        tern(lambda?(iterable), Iterator::foreach(iterable, fn), {
            Container::foreach(&iterable, fn)
        })
    }
}

"=== mlcpp: END include/std/Iterator.mlp (back to include/std/functional.mlp) ==="

-- autocurries until the nb of required args has been reached
var curry_required (requiredArgs, fn):{
    var >= (a, b):{
        a > b || a == b
    }
    var - (a, b):{
        a + b + b * -2
    }

    var curried _
    curried := (args...):{
        tern($#varargs - requiredArgs >= 0, fn(args...), {
            (args2...):{curried(args..., args2...)}
        })
    }
    curried
}

-- calling curry on a function with no required argument..
-- ..has no effect => use curry_required instead
var curry (fn, args...):{
    curry_required(len(fn), fn)(args...)
}

var curry_rhs (fn, rhs):{
    var res (lhs):{
        fn(lhs, rhs)
    }
    res
}

var foreach' {
    var foreach' (fn, container):{
        foreach(container, fn)
    }
    curry(foreach')
}

var map {
    var .. RangeIterator<=

    var Container::map (fn, container):{
        var res container
        foreach(1 .. len(res), (nth):{
            res[#nth] := fn(res[#nth])
        })
        res
    }

    var Iterator::map (fn, iterator):{
        iterator
        var peek ():{
            var peek iterator('peek)()
            tern(none?(peek), END, {
                var res fn(some(peek))
                Some(res)
            })
        }

        var next ():{
            var next iterator('next)()
            tern(none?(next), END, {
                var res fn(some(next))
                Some(res)
            })
        }

        '---

        var dispatcher (op):{
            tern(op == 'peek, peek, {
                tern(op == 'next, next, {
                    die("unknown iterator operation: `" + op + "`")
                })
            })
        }
        dispatcher
    }

    var < (lhs, rhs):{
        not(lhs > rhs || lhs == rhs)
    }
    var lambda? (x):{
        Str(x) == "<lambda>" && len(x) < 8
    }

    var map (fn, iterable):{
        tern(lambda?(iterable), Iterator::map(fn, iterable), {
            Container::map(fn, iterable)
        })
    }

    curry(map)
}

var filter {
    "accepts as input Str or List"
    var list? (x):{
        var str? {
            len(Str(x + '!)) == len(Str(x)) + 1
        }
        not(str?)
    }

    var .. RangeIterator<=

    var Container::filter (pred, container):{
        var list? list?(container)
        var res tern(list?, [], "")
        foreach(1 .. len(container), (nth):{
            pred(container[#nth]) && {
                !tern(list?, {res += container[#nth]}, {
                    res += [container[#nth]]
                })
            }
        })
        res
    }

    var Iterator::filter (pred, iterator):{
        iterator
        var peek ():{
            var curr peek(iterator)
            var stop_cond ():{
                none?(curr) || pred(some(curr))
            }
            until(stop_cond, ():{
                next(iterator)
                curr := peek(iterator)
            })
            curr
        }

        var next ():{
            var curr next(iterator)
            var stop_cond ():{
                none?(curr) || pred(some(curr))
            }
            until(stop_cond, ():{
                curr := next(iterator)
            })
            curr
        }

        '---

        var dispatcher (op):{
            tern(op == 'peek, peek, {
                tern(op == 'next, next, {
                    die("unknown iterator operation: `" + op + "`")
                })
            })
        }
        dispatcher
    }

    var < (lhs, rhs):{
        not(lhs > rhs || lhs == rhs)
    }
    var lambda? (x):{
        Str(x) == "<lambda>" && len(x) < 8
    }

    var filter (fn, iterable):{
        tern(lambda?(iterable), Iterator::filter(fn, iterable), {
            Container::filter(fn, iterable)
        })
    }

    curry(filter)
}

var reduce {
    var reduce (fn, acc, iterable):{
        foreach(iterable, (curr):{
            acc := fn(acc, curr)
        })
        acc
    }
    curry(reduce)
}

var compose (fn1, fn2, fns...):{
    var compose (fn1, fn2):{
        fn1
        fn2
        (x):{fn2(fn1(x))}
    }
    reduce(compose, fn1, List(fn2, fns...))
}

var split {
    var split (sep, str):{
        var res []
        var curr ""
        foreach(str, (c):{
            !tern(c == sep, {curr += c}, {
                res += [curr]
                curr := ""
            })
        })
        len(curr) > 0 && {res += [curr]}
        res
    }
    curry(split)
}

var join {
    var join (sep, list):{
        var res ""
        var first_it $true
        foreach(list, (str):{
            first_it || {res += sep}
            res += str
            first_it := $false
        })
        res
    }
    curry(join)
}

"=== mlcpp: END include/std/functional.mlp (finally back to include/misc/Stream.mlp) ==="

-- increasing range from "from" up to "to" included
var LazyRange<= (from, to):{
    "accepts as input Int, Char or Str"
    var str? (x):{
        len(Str(x + 0)) > len(Str(x))
    }
    var charInputs? {
        var charInputs? $true
        charInputs? &&= str?(from) && len(from) == 1
        charInputs? &&= str?(to) && len(to) == 1
        charInputs?
    }
    from := tern(charInputs?, Char, Int)(from)
    to := tern(charInputs?, Char, Int)(to)

    var LazyRange<= _
    LazyRange<= := (from, to):{
        tern(from > to, END, {
            Pair?(from, LazyRange<=(from + 1, to))
        })
    }

    LazyRange<=(from, to)
}

var subscript (subscriptable, nth):{
    nth == 0 && die("nth should differ from zero (less or greater)")

    var Stream::subscript (stream, nth):{
        nth > 0 || die("nth should be greater than zero")
        var subscript_rec _
        subscript_rec := (stream, nth):{
            tern(nth == 1, left(some(stream)), {
                subscript_rec(right(some(stream)), nth + -1)
            })
        }
        subscript_rec(stream, nth)
    }

    var lambda? (x):{
        var < (lhs, rhs):{
            not(lhs > rhs || lhs == rhs)
        }
        Str(x) == "<lambda>" && len(x) < 8
    }

    !tern(lambda?(subscriptable), subscriptable[#nth], {
        Stream::subscript(subscriptable, nth)
    })
}

var Stream::foreach (stream, fn):{
    var curr stream
    until(():{none?(curr)}, ():{
        fn(left(some(curr)))
        curr := right(some(curr))
    })
    stream
}

var Stream::foreach' {
    var Stream::foreach' (fn, stream):{
        Stream::foreach(stream, fn)
    }
    curry(Stream::foreach')
}

var Stream::map {
    var delay (x):{
        var delayed ():{x}
        delayed
    }

    var Stream::map _
    Stream::map := (fn, stream):{
        tern(none?(stream), END, {
            var curr fn(left(some(stream)))
            var next delay(Stream::map(fn, right(some(stream))))
            Pair?(curr, next())
        })
    }
    curry(Stream::map)
}

var Stream::filter {
    var delay (x):{
        var delayed ():{x}
        delayed
    }

    var Stream::filter _
    Stream::filter := (pred, stream):{
        tern(none?(stream), END, {
            var curr left(some(stream))
            var next delay(Stream::filter(pred, right(some(stream))))
            !tern(pred(curr), next(), {
                Pair?(curr, next())
            })
        })
    }
    curry(Stream::filter)
}

var Stream::reduce {
    var Stream::reduce (fn, acc, stream):{
        Stream::foreach(stream, (curr):{
            acc := fn(acc, curr)
        })
        acc
    }
    curry(Stream::reduce)
}

"package main"

"=== testing subscript on a LazyList ==="

var id (x):{
    print("evaluated: " + x)
    x
}

var stream LazyList(1, id(2), 3)

"we don't need to eval #2 to eval #3"
print(subscript(stream, 3))

"#2 gets evaluated here"
print(subscript(stream, 2))

"once an element has been evaluated once, it's not re-evaluated"
print(subscript(stream, 2))

"=== testing higher-order functions on a stream ==="

var |> (a, b):{
    b(a)
}

LazyRange<=(1, 10) |> Stream::map((x):{2 * x}) |> Stream::filter((x):{x % 10 == 0}) |> Stream::foreach'(print)
LazyRange<=(1, 1000) |> Stream::map((x):{2 * x}) |> Stream::filter((x):{x % 10 == 0}) |> Stream::reduce(+, 0) |> print
