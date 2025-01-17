defmodule EscapedFieldsTest do
  use ExUnit.Case
  import TestSupport.StreamHelpers

  test "parses empty escape sequences correctly" do
    stream = ["\"\",e"] |> to_line_stream
    result = CSV.decode!(stream) |> Enum.take(2)

    assert result == [["", "e"]]
  end

  test "collects rows with fields spanning multiple lines" do
    stream = ["a,\"be", "c,d\ne,f\"", "g,h", "i,j", "k,l"] |> to_line_stream
    result = CSV.decode!(stream) |> Enum.take(2)

    assert result == [["a", "be\nc,d\ne,f"], ~w(g h)]
  end

  test "does parse escape sequences in each field correctly" do
    stream = ["a,\"b\",\"c\"", "\"d\",e,\"f\"\"\""] |> to_line_stream
    result = CSV.decode(stream) |> Enum.take(2)

    assert result == [ok: ["a", "b", "c"], ok: ["d", "e", "f\""]]
  end

  test "collects rows with fields and escape sequences spanning multiple lines" do
    stream =
      [
        # line 1
        ",,\"\r\n",
        "field three of line one\r\n",
        "contains \"\"quoted\"\" text, \r\n",
        "multiple \"\"linebreaks\"\"\r\n",
        "and ends on a new line.\"\r\n",
        # line 2
        "line two has,\"a simple, quoted second field\r\n",
        "with one newline\",and a standard third field\r\n",
        # line 3
        "\"line three begins with an escaped field,\r\n",
        " continues with\",\"an escaped field,\r\n",
        "and ends\",\"with\r\n",
        "an escaped field\"\r\n",
        # line 4
        "\"field two in\r\n",
        "line four\",\"\r\n",
        "begins and ends with a newline\r\n",
        "\",\", and field three\r\n",
        "\"\"\"\"\r\n",
        "is full of newlines and quotes\r\n\"\r\n",
        # line 5
        "\"line five has an empty line in field two\",\"\r\n",
        "\r\n",
        "\",\"\"\"and a doubly quoted third field\r\n",
        "\"\"\"\r\n",
        # line 6 only contains quotes and new lines
        "\"\"\"\"\"\",\"\"\"\r\n",
        "\"\"\"\"\r\n",
        "\",\"\"\"\"\r\n",
        # line 7
        "line seven has an intermittent,\"quote\r\n",
        "right after\r\n",
        "\"\"a new line\r\n",
        "and\r\n",
        "ends with a standard, \"\"\",unquoted third field\r\n"
      ]
      |> to_stream

    result = CSV.decode!(stream) |> Enum.to_list()

    assert result == [
             [
               "",
               "",
               "\r\nfield three of line one\r\ncontains \"quoted\" text, \r\nmultiple \"linebreaks\"\r\nand ends on a new line."
             ],
             [
               "line two has",
               "a simple, quoted second field\r\nwith one newline",
               "and a standard third field"
             ],
             [
               "line three begins with an escaped field,\r\n continues with",
               "an escaped field,\r\nand ends",
               "with\r\nan escaped field"
             ],
             [
               "field two in\r\nline four",
               "\r\nbegins and ends with a newline\r\n",
               ", and field three\r\n\"\"\r\nis full of newlines and quotes\r\n"
             ],
             [
               "line five has an empty line in field two",
               "\r\n\r\n",
               "\"and a doubly quoted third field\r\n\""
             ],
             [
               "\"\"",
               "\"\r\n\"\"\r\n",
               "\""
             ],
             [
               "line seven has an intermittent",
               "quote\r\nright after\r\n\"a new line\r\nand\r\nends with a standard, \"",
               "unquoted third field"
             ]
           ]
  end

  1..100
  |> Enum.each(fn size ->
    @tag size: size
    test "collects rows with fields and escape sequences spanning multiple lines that are byte streamed with size #{size}",
         context do
      stream =
        ",,\"\r\nfield three of line one\r\ncontains \"\"quoted\"\" text, \r\nmultiple \"\"linebreaks\"\"\r\nand ends on a new line.\"\r\nline two has,\"a simple, quoted second field\r\nwith one newline\",and a standard third field\r\n\"line three begins with an escaped field,\r\n continues with\",\"an escaped field,\r\nand ends\",\"with\r\nan escaped field\"\r\n\"field two in\r\nline four\",\"\r\nbegins and ends with a newline\r\n\",\", and field three\r\n\"\"\"\"\r\nis full of newlines and quotes\r\n\"\r\n\"line five has an empty line in field two\",\"\r\n\r\n\",\"\"\"and a doubly quoted third field\r\n\"\"\"\r\n\"\"\"\"\"\",\"\"\"\r\n\"\"\"\"\r\n\",\"\"\"\"\r\nline seven has an intermittent,\"quote\r\nright after\r\n\"\"a new line\r\nand\r\nends with a standard, \"\"\",unquoted third field\r\n"
        |> to_byte_stream(context[:size])

      result = CSV.decode!(stream) |> Enum.to_list()

      assert result == [
               [
                 "",
                 "",
                 "\r\nfield three of line one\r\ncontains \"quoted\" text, \r\nmultiple \"linebreaks\"\r\nand ends on a new line."
               ],
               [
                 "line two has",
                 "a simple, quoted second field\r\nwith one newline",
                 "and a standard third field"
               ],
               [
                 "line three begins with an escaped field,\r\n continues with",
                 "an escaped field,\r\nand ends",
                 "with\r\nan escaped field"
               ],
               [
                 "field two in\r\nline four",
                 "\r\nbegins and ends with a newline\r\n",
                 ", and field three\r\n\"\"\r\nis full of newlines and quotes\r\n"
               ],
               [
                 "line five has an empty line in field two",
                 "\r\n\r\n",
                 "\"and a doubly quoted third field\r\n\""
               ],
               [
                 "\"\"",
                 "\"\r\n\"\"\r\n",
                 "\""
               ],
               [
                 "line seven has an intermittent",
                 "quote\r\nright after\r\n\"a new line\r\nand\r\nends with a standard, \"",
                 "unquoted third field"
               ]
             ]
    end
  end)
end
