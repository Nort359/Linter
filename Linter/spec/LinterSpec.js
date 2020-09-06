const Linter = require('../classes/Linter');
const fs = require('fs');

describe("Linter", function() {
    it("is exported correctly", function() {
        expect(Linter).toBeDefined();

        let linter = new Linter();
        expect(linter instanceof Linter).toBe(true);
    });

    it("is called within current directory by default", function() {
        expect(function() {
            return new Linter();
        }).not.toThrowError(TypeError);
    });

    it("is callable with a single file", function() {
        expect(function() {
            return (new Linter().handle('spec/resources/form.frm'));
        }).not.toThrowError(TypeError);
    });

    it("is callable with an array of paths", function() {
        expect(function() {
            return (new Linter().handle([
                'spec/resources/action.frm',
                'spec/resources/form.frm'
            ]));
        }).not.toThrowError(TypeError);
    });

    it("is callable with a glob", function() {
        expect(function() {
            return (new Linter().handle('./**/*.frm'));
        }).not.toThrowError(TypeError);
    });

});
