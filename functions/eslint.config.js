'use strict';

module.exports = [
  {
    files: ['**/*.js'],
    languageOptions: {ecmaVersion: 2022, sourceType: 'commonjs'},
    rules: {
      'max-len': ['error', {code: 100, ignoreStrings: true, ignoreTemplateLiterals: true}],
      'object-curly-spacing': ['error', 'never'],
      'quotes': ['error', 'single'],
      'semi': ['error', 'always'],
    },
  },
];
