const path = require("path")

var webpack = require('webpack');

// const MiniCssExtractPlugin = require("mini-css-extract-plugin");

module.exports = {
  entry: {
    bundle: "./src/index.js"
  },

  output: {
    filename: "[name].js",
    path: path.resolve(__dirname, "public")
  },

  mode: "production",
  devtool: "source-map",

  module: {
    rules: [
      {
        test: /\.js$/,
        exclude: [
          /node_modules/
        ],
        use: [
          { loader: "babel-loader" }
        ]
      }, 

      // {
      //   test: /\.s[ac]ss$/i,
      //   use: [
      //     process.env.NODE_ENV !== 'production'
      //     ? 'style-loader'
      //     : MiniCssExtractPlugin.loader,

      //     'style-loader',
      //     'css-loader',
      //     {
      //       loader: 'sass-loader',
      //       options: {
      //         sassOptions: {
      //           indentWidth: 4,
      //           includePaths: ['src/main.scss'],
      //         },
            
      //         // Prefer `dart-sass`
      //         implementation: require('sass'),
      //       },
      //     },
      //   ],
      // },
    ]
  }, 
  plugins: [
    new webpack.ProvidePlugin({
      $: "jquery",
      jQuery: "jquery"
    })
  ]
  // plugins: [
  //   new MiniCssExtractPlugin({
  //     // Options similar to the same options in webpackOptions.output
  //     // both options are optional
  //     filename: '[name].css',
  //     chunkFilename: '[id].css',
  //   }),
// ],
}
