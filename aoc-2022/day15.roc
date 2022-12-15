app "aoc-2022"
    packages { pf: "https://github.com/roc-lang/basic-cli/releases/download/0.1.2/3bKbbmgtIfOyC6FviJ9o8F8xqKutmXgjCJx3bMfVTSo.tar.br" }
    imports [
        pf.Stdout,
        pf.Task.{ Task },
        # pf.File,
        # pf.Path.{ Path },
        Parser.Core.{ Parser, parsePartial, parse, oneOrMore, maybe, const, sepBy, keep, skip, buildPrimitiveParser },
        Parser.Str.{ codeunit },
        Json,
        # TerminalColor.{ Color, withColor },
    ]
    provides [ main, stateToStr ] to pf

main : Task {} []
main =

    task =

        {initialState & data : sampleData}
        |> part1
        |> Stdout.line


        # fsSample = process sampleInput 
        # fileInput <- File.readUtf8 (Path.fromStr "input-day-7.txt") |> Task.map Str.toUtf8 |> Task.await
        # fsFile = process fileInput
        # {} <- run (withColor "Sample:" Green) fsSample part1 |> Task.await
        # {} <- run (withColor "Part 1:" Green) fsFile part1 |> Task.await
        # {} <- run (withColor "Part 2:" Green) fsFile part2 |> Task.await

    Task.onFail task \_ -> crash "Oops, something went wrong."


initialState = {
    data : [],
    minX : 0, 
    maxX : 0,
    minY : 0,
    maxY : 0
}

part1 = \state -> {}
    state 
    |> updateRanges
    |> .minX 
    |> Num.toStr

updateRanges = \state ->
    
    sxRange = getMinMax state.data .sx  
    syRange = getMinMax state.data .sy  
    bxRange = getMinMax state.data .bx  
    byRange = getMinMax state.data .by

    xRanges = 
        [state.minX, state.maxX] 
        |> List.concat sxRange
        |> List.concat bxRange
        |> List.sortAsc
    
    yRanges = 
        [state.minY, state.maxY] 
        |> List.concat syRange
        |> List.concat byRange
        |> List.sortAsc

    minX = List.first xRanges |> Result.withDefault 0
    maxX = List.last xRanges |> Result.withDefault 0
    minY = List.first yRanges |> Result.withDefault 0
    maxY = List.last yRanges |> Result.withDefault 0
    
    {state & minX, maxX, minY, maxY}

testRanges = updateRanges {initialState & data : sampleData }

expect testRanges.minX == -2
expect testRanges.maxX == 25
expect testRanges.minY == 0
expect testRanges.maxY == 22

getMinMax = \data, selector ->
    sorted = 
        List.map data selector 
        |> List.sortAsc
    
    when sorted is 
        [smallest, .. ,biggest] -> [smallest, biggest]
        _ -> crash "expected more than two numbers"

expect
    result = getMinMax sampleData .bx
    result == [-2, 25]

sampleData =
    when parse inputParser (Str.toUtf8 sampleInput) List.isEmpty is 
        Ok data -> data 
        Err (ParsingFailure msg) -> crash "Oops, something went wrong parsing input:\(msg)"
        Err (ParsingIncomplete leftover) -> 
            l = leftover |> Str.fromUtf8 |> Result.withDefault "badUtf8"
            crash "Oops, didn't parse everything, leftover:\(l)"

expect List.get sampleData 0 == Ok {sx: 2, sy : 18, bx : -2, by : 15}

inputParser =

    stuff = chompWhile (notDigitOrDash)
    
    line = 
        const (\sx -> \sy -> \bx -> \by ->
            {sx, sy, bx, by}
        )
        |> skip stuff
        |> keep int 
        |> skip stuff
        |> keep int 
        |> skip stuff
        |> keep int 
        |> skip stuff
        |> keep int

    sepBy line (codeunit '\n')


sampleInput =
    """
    Sensor at x=2, y=18: closest beacon is at x=-2, y=15
    Sensor at x=9, y=16: closest beacon is at x=10, y=16
    Sensor at x=13, y=2: closest beacon is at x=15, y=3
    Sensor at x=12, y=14: closest beacon is at x=10, y=16
    Sensor at x=10, y=20: closest beacon is at x=10, y=16
    Sensor at x=14, y=17: closest beacon is at x=10, y=16
    Sensor at x=8, y=7: closest beacon is at x=2, y=10
    Sensor at x=2, y=0: closest beacon is at x=2, y=10
    Sensor at x=0, y=11: closest beacon is at x=2, y=10
    Sensor at x=20, y=14: closest beacon is at x=25, y=17
    Sensor at x=17, y=20: closest beacon is at x=21, y=22
    Sensor at x=16, y=7: closest beacon is at x=15, y=3
    Sensor at x=14, y=3: closest beacon is at x=15, y=3
    Sensor at x=20, y=1: closest beacon is at x=15, y=3
    """

chompWhile : (a -> Bool) -> Parser (List a) {} | a has Eq
chompWhile = \check ->
    buildPrimitiveParser \input ->

        index = 
            List.walkUntil input 0 \i, elem ->
                if check elem then 
                    Continue (i + 1)
                else 
                    Break i

        Ok {
            val : {},
            input : List.drop input index,
        }

notDigitOrDash = \i ->
    when i is 
        '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' | '-' -> Bool.false
        _ -> Bool.true

expect 
    result = parsePartial (chompWhile (notDigitOrDash)) (Str.toUtf8 "abc -") 
    result == Ok {val : {}, input : ['-']}

digit : Parser (List U8) Nat
digit =
    input <- buildPrimitiveParser

    when input is 
        ['0',..] -> Ok { val: 0, input: List.dropFirst input }
        ['1',..] -> Ok { val: 1, input: List.dropFirst input }
        ['2',..] -> Ok { val: 2, input: List.dropFirst input }
        ['3',..] -> Ok { val: 3, input: List.dropFirst input }
        ['4',..] -> Ok { val: 4, input: List.dropFirst input }
        ['5',..] -> Ok { val: 5, input: List.dropFirst input }
        ['6',..] -> Ok { val: 6, input: List.dropFirst input }
        ['7',..] -> Ok { val: 7, input: List.dropFirst input }
        ['8',..] -> Ok { val: 8, input: List.dropFirst input }
        ['9',..] -> Ok { val: 9, input: List.dropFirst input }
        _ -> Err (ParsingFailure "not a digit")
            
int : Parser (List U8) I64
int =
    const (\maybeDash -> \digits -> 
        sign = when maybeDash is 
            Ok _ -> -1
            Err _ -> 1
        
        List.walk digits 0 (\sum, d -> sum * 10 + d)
        |> Num.toI64
        |> Num.mul sign
    )
    |> keep (maybe (codeunit '-'))
    |> keep (oneOrMore digit)

expect 
    result = parsePartial int (Str.toUtf8 "-123456789abc") 
    result == Ok {val : -123456789i64, input : ['a', 'b', 'c']}

stateToStr = \state ->
    when Str.fromUtf8 (Encode.toBytes state Json.toUtf8) is 
        Ok str -> str
        Err _ -> crash "unable to encode state to Json"