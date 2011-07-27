module shellpress
  class Posts < Thor
    include Thor::Actions

    desc "delete [POST ID/SLUG]", "deletes a post, attachment, or page of the specified ID or path (slug)"
    method_option :force, :type => :boolean, :aliases => %w(-f), :default => true,
      :desc => "Force delete post bypassing the Trash"
    method_option :type, :type => :string, :aliases => %w(-t), :default => "post",
      :desc => "The type of object to delete. Default valid types: post, page, attachment, revision, nav_menu. Custom post types are also supported"
    def delete(id)
      force = options[:force]
      type = options[:type]

      php = "<?php include 'wp-load.php';"

      if id =~ /\d+/
        php << "wp_delete_post(#{id}, #{force});"
      else
        php << "$post = get_page_by_path('#{id}', OBJECT, '#{type}');"
        php << "if ($post) wp_delete_post($post->ID, #{force});"
      end

      php << "?>"

      File.open("temp.php", "w") {|f| f.write(php)}
      run "php -q temp.php"
      remove_file "temp.php", :verbose => false

    end
  end #posts
end #shellpress

