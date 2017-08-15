
describe "Table", ->

  beforeAll ->
    db.init users: []

  describe ".insert()", ->

    it "appends a row", ->
      query = users.insert {id: 1}
      expect(1).toBe query._run().inserted
      expect(1).toBe db._tables.users.length

    it "clones the row before inserting it", ->
      query = users.insert row = {id: 2}
      query._run()
      user = db._tables.users[1]
      expect(row).not.toBe user
      expect(row.id).toBe user.id

    it "throws for a duplicate primary key", ->
      query = users.insert {id: 1}
      expect(1).toBe query._run().errors
      expect(2).toBe db._tables.users.length

    it "generates a UUID if no primary key is defined", ->
      query = users.insert {}
      res = query._run()
      key = res.generated_keys[0]
      expect(key).toBe users.get(key)._run().id
      expect(res.inserted).toBe 1

    it "can insert multiple rows at once", ->
      query = users.insert [{name: "Joe"}, {name: "Jim"}]
      res = query._run()
      expect(res.inserted).toBe 2
      expect(res.generated_keys.length).toBe 2

    it "still inserts a row if other rows have duplicate primary keys", ->
      query = users.insert [{id: 2}, {id: 3}, {id: 1}]
      res = query._run()
      expect(res.errors).toBe 2
      expect(res.inserted).toBe 1

    it "supports nested queries", ->
      users.insert(id: 4, name: db.expr "John")._run()
      expect(users.get(4)._run()).toEqual {id: 4, name: "John"}

  describe ".get()", ->

    it "gets a row by its primary key", ->
      res = users.get(1)._run()
      expect(res.id).toBe 1

    it "clones the row before returning it", ->
      user1 = users.get 1
      expect(user1._run()).not.toBe user1._run()

    it "returns null if a row never existed", ->
      expect(null).toBe users.get(100)._run()

    # it "supports sub-queries", ->

  describe ".getAll()", ->

    beforeAll ->
      Promise.all [
        users.get(2).update {friendCount: 5}
        users.get(3).update {friendCount: 5}
      ]

    it "gets matching rows", ->
      query = users.getAll 1, 2
      expect(2).toBe query._run().length

    it "can use secondary indexes", ->
      query = users.getAll 5, {index: "friendCount"}
      expect(2).toBe query._run().length

    # it "supports sub-queries", ->

    # it "can match an array", ->

  describe ".delete()", ->

    it "deletes every row in the table", ->
      count = db._tables.users.length
      query = users.delete()
      expect(count).toBe query._run().deleted
      expect(0).toBe db._tables.users.length
