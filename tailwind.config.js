module.exports = {
  content: [
    "./app/views/**/*.html.erb",
    "./app/helpers/**/*.rb",
    "./app/javascript/**/*.js",
  ],
  theme: {
    // ← extend ではなく直下で上書き！
    fontFamily: {
      sans: ['"Kaisei Decol"', "serif"],  // preflightの既定を置き換え
    },
    extend: {
      // 任意：個別指定用クラスも残したいなら
      fontFamily: {
        mushroom: ['"Kaisei Decol"', "serif"],
      },
    },
  },
  plugins: [],
};
