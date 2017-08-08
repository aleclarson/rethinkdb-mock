
utils = require "../js/utils"

describe "utils.equals()", ->

  it "returns false if the values are not equal", ->
    expect(utils.equals(1, 0)).toBe false
    expect(utils.equals("a", "b")).toBe false
    expect(utils.equals(true, false)).toBe false

  describe "comparing arrays", ->

    it "is recursive", ->
      a = [1, [2, 3]]
      b = [1, [2, 3]]
      expect(utils.equals(a, b)).toBe true
      b[1].push 4
      expect(utils.equals(a, b)).toBe false

    it "respects ordering", ->
      expect(utils.equals([1, 2], [2, 1])).toBe false

    it "compares objects", ->
      a = [{a: 1}]
      b = [{a: 1}]
      expect(utils.equals(a, b)).toBe true
      b[0].b = 2
      expect(utils.equals(a, b)).toBe false

  describe "comparing objects", ->

    it "is recursive", ->
      a = {a: {b: 1, c: 2}}
      b = {a: {b: 1, c: 2}}
      expect(utils.equals(a, b)).toBe true
      b.a.d = 3
      expect(utils.equals(a, b)).toBe false

    it "does not respect ordering", ->
      a = {a: 1, b: 2}
      b = {b: 2, a: 1}
      expect(utils.equals(a, b)).toBe true

    it "compares arrays", ->
      a = {a: [1, 2]}
      b = {a: [1, 2]}
      expect(utils.equals(a, b)).toBe true
      b.a.push 3
      expect(utils.equals(a, b)).toBe false

describe "utils.flatten()", ->

  it "merges nested arrays into a single array", ->
    array = utils.flatten [1, [2], 3, [4], 5]
    expected = [1, 2, 3, 4, 5]
    expect(utils.equals(array, expected)).toBe true

  it "is recursive", ->
    array = utils.flatten [[[1], [2, 3]], [[4, 5], 6]]
    expected = [1, 2, 3, 4, 5, 6]
    expect(utils.equals(array, expected)).toBe true
