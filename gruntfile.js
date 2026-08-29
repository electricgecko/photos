module.exports = function (grunt) {

  grunt.initConfig({

    pkg: grunt.file.readJSON('package.json'),
		
		sass: {
			dist: {
				options: {
					style: 'compressed'
				},
				files: {
					'dist/m.css': ['src/m.scss']
				}
			}
		},
		
		terser: {
			dist: {
				files: {
					'dist/m.js': ['src/m.js']
				},
				options: {
					warnings: 'true'
				}	
			},
		},

		watch: {
		  css: {
		    files: 'src/*.scss',
		    tasks: ['sass'],
		    options: {
		      livereload: true
		    },
		  },
			js: {
				files: 'src/*.js',
				tasks: ['terser'],
				options: {
					livereload: true
				}
			}
		}
  });
	
	grunt.loadNpmTasks('grunt-terser');
	grunt.loadNpmTasks('grunt-contrib-watch');
	grunt.loadNpmTasks('grunt-contrib-sass');
	grunt.registerTask('default', ['sass', 'terser']);
};
