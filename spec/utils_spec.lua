describe("utils", function()
  local utils

  setup(function()
    _G.log = require("loglua")
    utils = require("PudimServer.utils")
  end)

  describe("createInterface", function()
    it("creates an interface with __IsInterface flag", function()
      local inter = utils:createInterface{ name = "string" }
      assert.is_true(inter.__IsInterface)
    end)

    it("stores fields correctly", function()
      local inter = utils:createInterface{ name = "string", age = "number" }
      assert.are.equal("string", inter.__fields.name)
      assert.are.equal("number", inter.__fields.age)
    end)

    it("supports multiple types for a field", function()
      local inter = utils:createInterface{ value = {"string", "number"} }
      assert.are.same({"string", "number"}, inter.__fields.value)
    end)

    it("extends another interface", function()
      local base = utils:createInterface{ name = "string" }
      local child = utils:createInterface({ age = "number" }, base)
      assert.are.equal("string", child.__fields.name)
      assert.are.equal("number", child.__fields.age)
    end)

    it("saves interfaces in __savedTypes", function()
      utils.__savedTypes = nil
      local inter = utils:createInterface{ x = "number" }
      assert.is_table(utils.__savedTypes)
      assert.is_true(#utils.__savedTypes >= 1)
    end)
  end)

  describe("verifyTypes", function()
    it("validates a simple string type", function()
      local ok, err = utils:verifyTypes("hello", "string")
      assert.is_true(ok)
    end)

    it("fails for wrong simple type", function()
      local ok, err = utils:verifyTypes(123, "string")
      assert.is_false(ok)
    end)

    it("validates a table against an interface", function()
      local inter = utils:createInterface{ name = "string", age = "number" }
      local ok = utils:verifyTypes({ name = "Davi", age = 25 }, inter)
      assert.is_true(ok)
    end)

    it("fails when a field is missing", function()
      local inter = utils:createInterface{ name = "string", age = "number" }
      local ok, err = utils:verifyTypes({ name = "Davi" }, inter)
      assert.is_false(ok)
      assert.is_truthy(err:find("absent"))
    end)

    it("fails when a field has wrong type", function()
      local inter = utils:createInterface{ name = "string" }
      local ok, err = utils:verifyTypes({ name = 123 }, inter)
      assert.is_false(ok)
      assert.is_truthy(err:find("invalid"))
    end)

    it("accepts multi-type fields", function()
      local inter = utils:createInterface{ value = {"string", "number"} }
      assert.is_true(utils:verifyTypes({ value = "hello" }, inter))
      assert.is_true(utils:verifyTypes({ value = 42 }, inter))
    end)

    it("validates nested interfaces", function()
      local inner = utils:createInterface{ x = "number" }
      local outer = utils:createInterface{ child = inner }
      local ok = utils:verifyTypes({ child = { x = 10 } }, outer)
      assert.is_true(ok)
    end)

    it("fails nested interface validation", function()
      local inner = utils:createInterface{ x = "number" }
      local outer = utils:createInterface{ child = inner }
      local ok, err = utils:verifyTypes({ child = { x = "not a number" } }, outer)
      assert.is_false(ok)
    end)

    it("rejects non-table when interface expected", function()
      local inter = utils:createInterface{ name = "string" }
      local ok, err = utils:verifyTypes("not a table", inter)
      assert.is_false(ok)
      assert.is_truthy(err:find("expected object"))
    end)
  end)

  describe("loadMessageOnChange", function()
    it("calls printer on first message", function()
      utils.mensagens = nil
      local called = false
      utils:loadMessageOnChange("test-chan", "hello", function(msg)
        called = true
        assert.are.equal("hello", msg)
      end)
      assert.is_true(called)
    end)

    it("does not call printer for same message", function()
      utils.mensagens = nil
      local count = 0
      local printer = function() count = count + 1 end
      utils:loadMessageOnChange("test-chan2", "msg1", printer)
      utils:loadMessageOnChange("test-chan2", "msg1", printer)
      assert.are.equal(1, count)
    end)

    it("calls printer again when message changes", function()
      utils.mensagens = nil
      local count = 0
      local printer = function() count = count + 1 end
      utils:loadMessageOnChange("test-chan3", "msg1", printer)
      utils:loadMessageOnChange("test-chan3", "msg2", printer)
      assert.are.equal(2, count)
    end)
  end)

  describe("file I/O", function()
    local tmpfile = "/tmp/pudim_test_file.txt"

    after_each(function()
      os.remove(tmpfile)
    end)

    it("writes and reads a file", function()
      utils:writeFile(tmpfile, "hello pudim")
      local content = utils:getContentFile(tmpfile)
      assert.are.equal("hello pudim", content)
    end)

    it("checkFilesExist returns true for existing file", function()
      utils:writeFile(tmpfile, "exists")
      assert.is_true(utils:checkFilesExist(tmpfile))
    end)

    it("checkFilesExist returns false for missing file", function()
      assert.is_false(utils:checkFilesExist("/tmp/nonexistent_pudim_file.txt"))
    end)
  end)
end)
