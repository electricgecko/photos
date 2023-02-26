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
		},
		
		image_resize: {
			resize_thumbs: {
				options: {
					width: 400,
					height: 400,
					overwrite: true,
					autoOrient: true
				},
				files: [{
					ext: '.jpg',
					src: ['src/input/*.jpg','src/input/*.JPG','src/input/*.jpeg','src/input/*.JPEG'],
					dest: 'src/input/thumb/'
				}],
			},
			
			resize_full: {
				options: {
					width: 2200,
					height: 2200,
					overwrite: true,
					autoOrient: true
				},
				files: [{
					ext: '.jpg',
					src: ['src/input/*.jpg','src/input/*.JPG','src/input/*.jpeg','src/input/*.JPEG'],
					dest: 'src/input/'
				}]
			},
		},
		
		imageoptim: {
			myTask: {
				src: ['src/input/**'],
				filter: 'isFile'
			}
		},
		
		copy: {
			copyfolder: {
				files: [
				{
					expand: true,
					overwrite: true,
					timestamp: true,
					cwd: 'src/input/thumb/',
					src: ['*'],
					ext: '.jpg',
					dest: 'dist/img/thumb/',
				},
				],
			},
			
			copyfiles: {
				files: [
				{
					expand: true,
					overwrite: true,
					timestamp: true,
					cwd: 'src/input/',
					src: ['*.jpg', '*.JPG', '*.jpeg', '*.JPEG'],
					ext: '.jpg',
					dest: 'dist/img/',
				},
				],
			},
		}
  });
	
	grunt.loadNpmTasks('grunt-terser');
	grunt.loadNpmTasks('grunt-contrib-watch');
	grunt.loadNpmTasks('grunt-contrib-sass');
	grunt.loadNpmTasks('grunt-image-resize');
	grunt.loadNpmTasks('grunt-imageoptim');
	grunt.loadNpmTasks('grunt-contrib-copy');
	grunt.registerTask('default', ['sass', 'terser']);
	grunt.registerTask('make', ['image_resize', 'imageoptim', 'copy']);
};
