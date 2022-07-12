local helpers = require('test.functional.helpers')(after_each)
local Screen = require('test.functional.ui.screen')
local clear = helpers.clear
local command = helpers.command
local eq = helpers.eq
local eval = helpers.eval
local feed = helpers.feed
local meths = helpers.meths

before_each(clear)

describe('Ex mode', function()
  it('supports command line editing', function()
    local function test_ex_edit(expected, cmd)
      feed('gQ' .. cmd .. '<C-b>"<CR>')
      local ret = eval('@:[1:]')  -- Remove leading quote.
      feed('visual<CR>')
      eq(meths.replace_termcodes(expected, true, true, true), ret)
    end
    command('set sw=2')
    test_ex_edit('bar', 'foo bar<C-u>bar')
    test_ex_edit('1<C-u>2', '1<C-v><C-u>2')
    test_ex_edit('213', '1<C-b>2<C-e>3')
    test_ex_edit('2013', '01<Home>2<End>3')
    test_ex_edit('0213', '01<Left>2<Right>3')
    test_ex_edit('0342', '012<Left><Left><Insert>3<Insert>4')
    test_ex_edit('foo ', 'foo bar<C-w>')
    test_ex_edit('foo', 'fooba<Del><Del>')
    test_ex_edit('foobar', 'foo<Tab>bar')
    test_ex_edit('abbreviate', 'abbrev<Tab>')
    test_ex_edit('1<C-t><C-t>', '1<C-t><C-t>')
    test_ex_edit('1<C-t><C-t>', '1<C-t><C-t><C-d>')
    test_ex_edit('    foo', '    foo<C-d>')
    test_ex_edit('    foo0', '    foo0<C-d>')
    test_ex_edit('    foo^', '    foo^<C-d>')
    test_ex_edit('foo', '<BS><C-H><Del><kDel>foo')
    -- default wildchar <Tab> interferes with this test
    command('set wildchar=<c-e>')
    test_ex_edit('a\tb', 'a\t\t<C-H>b')
    test_ex_edit('\tm<C-T>n', '\tm<C-T>n')
    command('set wildchar&')
  end)

  it('substitute confirmation prompt', function()
    command('set noincsearch nohlsearch inccommand=')
    local screen = Screen.new(60, 6)
    screen:attach()
    command([[call setline(1, ['foo foo', 'foo foo', 'foo foo'])]])
    command([[set number]])
    feed('gQ')
    screen:expect([[
        1 foo foo                                                 |
        2 foo foo                                                 |
        3 foo foo                                                 |
                                                                  |
      Entering Ex mode.  Type "visual" to go to Normal mode.      |
      :^                                                           |
    ]])

    feed('%s/foo/bar/gc<CR>')
    screen:expect([[
        1 foo foo                                                 |
                                                                  |
      Entering Ex mode.  Type "visual" to go to Normal mode.      |
      :%s/foo/bar/gc                                              |
        1 foo foo                                                 |
          ^^^^                                                     |
    ]])
    feed('n<CR>')
    screen:expect([[
      Entering Ex mode.  Type "visual" to go to Normal mode.      |
      :%s/foo/bar/gc                                              |
        1 foo foo                                                 |
          ^^^n                                                    |
        1 foo foo                                                 |
              ^^^^                                                 |
    ]])
    feed('y<CR>')

    feed('q<CR>')
    screen:expect([[
        1 foo foo                                                 |
              ^^^y                                                |
        2 foo foo                                                 |
          ^^^q                                                    |
        2 foo foo                                                 |
      :^                                                           |
    ]])

    -- Pressing enter in ex mode should print the current line
    feed('<CR>')
    screen:expect([[
        1 foo foo                                                 |
              ^^^y                                                |
        2 foo foo                                                 |
          ^^^q                                                    |
        3 foo foo                                                 |
      :^                                                           |
    ]])

    feed(':vi<CR>')
    screen:expect([[
        1 foo bar                                                 |
        2 foo foo                                                 |
        3 ^foo foo                                                 |
      ~                                                           |
      ~                                                           |
                                                                  |
    ]])
  end)
end)
