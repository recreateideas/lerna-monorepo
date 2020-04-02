module.exports = {
    extends: ['@commitlint/config-conventional'],
    rules:{
        'scope-case': [0, 'always', 'lower-case'],
        'scope-empty': [2, 'never', 'never'],
    },
}; 