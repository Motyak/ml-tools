"=== mlp: BEGIN ./std/cond.mlp ================================================"

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

```
    tern should ALWAYS be considered before
    deciding to use a CaseAnalysis,
    as tern is easier to read and suits most situtations.

    On the other hand, CaseAnalysis is very powerful but
    require you to define an additional variable
    (two of them if you need to store a result)
```
var CaseAnalysis ():{
    var end $false
    var fn (cond, do):{
        end == $nil && {
            die("additional case succeeding a fallthrough case")
        }
        end ||= cond && {
            _ := do
            $true
        }
        "NOTE: don't eval cond if end"
        end == $false && cond == $nil && {
            _ := do
            end := $nil
        }
        ;
    }
    fn
}

"=== mlp: END ./std/cond.mlp (finally back to std/functional.mlp) ============="
"=== mlp: BEGIN ./std/loops.mlp ==============================================="

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

"=== mlp: END ./std/loops.mlp (finally back to std/functional.mlp) ============"
"=== mlp: BEGIN ./std/Iterator.mlp ============================================"


"=== mlp: BEGIN ./std/Optional.mlp ============================================"


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

"=== mlp: END ./std/Optional.mlp (back to ./std/Iterator.mlp) ================="
"=== mlp: BEGIN ./std/LazyList.mlp ============================================"


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

"=== mlp: END ./std/LazyList.mlp (back to ./std/Iterator.mlp) ================="

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
        $type(x) == 'Lambda
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
    var curr init

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
            $type(x) == 'Str
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

        var lambda? (x):{
            $type(x) == 'Lambda
        }
        tern(lambda?(iterable), Iterator::foreach(iterable, fn), {
            Container::foreach(&iterable, fn)
        })
    }
}

"=== mlp: END ./std/Iterator.mlp (finally back to std/functional.mlp) ========="

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
    var curried (lhs):{
        fn(lhs, rhs)
    }
    curried
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


    var lambda? (x):{
        $type(x) == 'Lambda
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
        $type(x) == 'List
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

    var lambda? (x):{
        $type(x) == 'Lambda
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

"package main"

var |> (a, b):{
    b(a)
}

var upper (OUT c):{
    var <= (a, b):{
        a > b == $false
    }
    var - (a, b):{
        a + b + b * -2
    }
    var ascii (c):{
        Int(Char(c))
    }

    tern(ascii(c) <= ascii('Z), c, {
        var local_c Char(c)
        local_c -= ascii('a) - ascii('A)
        c := local_c
        local_c
    })
}

RangeIterator<=(1, 10) |> map((n):{n * 2}) |> filter((n):{n % 10 == 0}) |> foreach'(print)
RangeIterator<=(1, 100) |> map((n):{n * 2}) |> filter((n):{n % 10 == 0}) |> reduce(+, 0) |> print
compose((n):{n + 1}, (n):{n * 2})(10) |> print
"a,b,c" |> split(",") |> map(upper) |> join("") |> print

var gt20 curry_rhs(>, 20)
gt20(21) |> print
gt20(19) |> print

var my+ curry_required(3, +)
my+(1, 2)(3) |> print
my+(1)(2, 3) |> print
my+(1)(2)(3) |> print
