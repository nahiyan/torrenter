const path = require('path')

module.exports = {
  entry: './src/js/index.js',
  output: {
    path: path.resolve(__dirname, '../dist'),
    filename: 'bundle.js'
  },
  module: {
    rules: [
      {
        test: /\.s[ac]ss$/i,
        use: [
          // Creates `style` nodes from JS strings
          'style-loader',
          // Translates CSS into CommonJS
          'css-loader',
          {
            loader: 'postcss-loader', // Run postcss actions
            options: {
              plugins: function () {
                // postcss plugins, can be exported to postcss.config.js
                return [require('autoprefixer')]
              }
            }
          },
          // Compiles Sass to CSS
          'sass-loader'
        ]
      }
    ]
  }
}
