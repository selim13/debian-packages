// yarn eleventy dotenv_config_path=../.env
require('dotenv/config');

module.exports = function (eleventyConfig) {
  eleventyConfig.addPassthroughCopy({ favicon: './' });
};
