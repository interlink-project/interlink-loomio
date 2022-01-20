class API::V1::AssetsController < API::V1::RestfulController

    # redirect to the creation of a new thread
    def instantiator
        redirect_to get_base_endpoint + '/d/new'
    end

    # redirect to the page of the specified resource (group or thread)
    def gui
        puts params
        id = params['asset_id']
        if id.starts_with?('g-')
            group = find_and_authorize_group(id_to_key(id))
            redirect_to get_base_endpoint + '/g/' + group.handle
        elsif id.starts_with?('d-')
            discussion = find_and_authorize_discussion(id_to_key(id))
            redirect_to get_base_endpoint + '/d/' + discussion.key + '/' + name_to_url(discussion.title)
        else 
            render json: {error: 'Unknown asset type'}, root: false, status: 422    
        end

    end

    # return specified Group of the current user
    def show 
        id = params['id']
        if id.starts_with?('g-')
            group = find_and_authorize_group(id_to_key(id))
            render json: group_to_asset(group), status: 200    
        elsif id.starts_with?('d-')
            discussion = find_and_authorize_discussion(id_to_key(id))
            group = Group.find(discussion.group_id)
            render json: discussion_to_asset(discussion, group), status: 200    
        else 
            render json: {error: 'Unknown asset type'}, root: false, status: 422    
        end
    end

    # create and return an asset defined by the specified object
    # can create group (default) or discussion.
    # Discussionshould have parentId defined.
    def create
        if !current_user.is_logged_in?
            respond_forbidden
        end

        type = params['asset']['type'] || 'group'
        name = params['asset']['name']
        parent_id = params['asset']['parentId']
        members = params['asset']['members'] || []
        if parent_id
            parent_id = id_to_key(parent_id.to_i)
        end
        
        if type == 'group'
            if parent_id
                parent_id = find_and_authorize_group(parent_id).id
            end
            group = create_group(name, members, parent_id)
            render json: group_to_asset(group), status: 200
        elsif type == 'discussion'
            group = find_and_authorize_group(parent_id)
            discussion = create_discussion(name, group)
            render json: discussion_to_asset(discussion, group), status: 200
        else 
            render json: {error: 'Unknown asset type'}, root: false, status: 422    
        end
    end

    # update operation for discussion or group. Can change name at the moment    
    def update
        if !current_user.is_logged_in?
            respond_forbidden
        end
        id = params['id']
        parent_id = params['asset']['parentId']
        name = params['asset']['name']
        members = params['asset']['members'] || nil

        if id.starts_with?('g-')
            group = find_and_authorize_group(id_to_key(id))
            if parent_id
                parent_id = find_and_authorize_group(parent_id).id
            end
            update_group(group, name, members, parent_id)
            render json: group_to_asset(group), status: 200    
        elsif id.starts_with?('d-')
            discussion = find_and_authorize_discussion(id_to_key(id))
            group = Group.find(discussion.group_id)
            update_discussion(discussion, name, members)
            render json: discussion_to_asset(discussion, group), status: 200    
        else 
            render json: {error: 'Unknown asset type'}, root: false, status: 422    
        end

    end

    # update operation for discussion or group. Can change name at the moment    
    def destroy
        if !current_user.is_logged_in?
            respond_forbidden
        end
        id = params['id']
        
        if id.starts_with?('g-')
            group = find_and_authorize_group(id_to_key(id))
            GroupService.destroy(group: group, actor: current_user)
            render json: {}, status: 200    
        elsif id.starts_with?('d-')
            discussion = find_and_authorize_discussion(id_to_key(id))
            DiscussionService.discard(discussion: discussion, actor: current_user)
            render json: {}, status: 200    
        else 
            render json: {error: 'Unknown asset type'}, root: false, status: 422    
        end

    end

    private 
    
    def find_and_authorize_group(key)
        group = Group.find_by(key: key).parent_or_self
        puts current_user.username
        current_user.ability.authorize!(:show, group)
        return group
    end
    
    def find_and_authorize_discussion(key)
        discussion = Discussion.find_by(key: key)
        current_user.ability.authorize!(:show, discussion)
        return discussion
    end

    def create_group(name, members, parent_id)
        parent_handle = nil
        if parent_id
            parent_handle = Group.find(parent_id).handle
        end

        group = Group.new(name: params['asset']['name'],
                 group_privacy: 'closed',
                 handle: suggest_handle(name, parent_handle),
                 parent_id: parent_id,
                 is_visible_to_public: false,
                 discussion_privacy_options: 'private_only', creator: current_user)
        
        GroupService.create(group: group, actor: current_user)
        members.each do |member|
            username = member['username']
            is_group_admin = is_admin_role(member['roles'])
            GroupService.invite(group:group, params: {recipient_emails: [username]}, actor: group.creator)
            user = User.find_by(email: username)
            if is_group_admin
                group.add_admin! user
            else 
                group.add_member! user
            end
        end
        return group
    end

    def update_group(group, name, members, parent_id)
        if name
            group.update(name: name, handle: suggest_handle(name, parent_handle))
        end      
        return group
    end
    def update_discussion(discussion, name, members)
        if name
            discussion.update(title: name)
        end      
        return group
    end

    def create_discussion(name, group)
        discussion = Discussion.new(title: name, private: true, author: current_user, group: group)
        DiscussionService.create(discussion: discussion, actor: discussion.author)     
        return discussion
    end

    def suggest_handle(name, parent_handle)
        GroupService.suggest_handle(name: name, parent_handle: parent_handle)
    end

    def is_admin_role(roles)
        roles.include? 'owner'
    end

    def group_to_asset(group)
        group_id = get_id(group.key, 'g')
        { "id": group_id, "name": group.name, "type": "group", "url": get_endpoint + group_id }
    end
    def discussion_to_asset(discussion, group)
        id = get_id(discussion.key, 'd')
        group_id = get_id(group.key, 'g')
        { "id": id, "name": discussion.title, "type": "discussion", "parent": group_id, "url": get_endpoint + id }
    end

    def get_endpoint
        (ENV['FORCE_SSL'] ? 'https://' : 'http://') + ENV['CANONICAL_HOST'] + '/api/v1/assets/'
    end

    def get_base_endpoint
        (ENV['FORCE_SSL'] ? 'https://' : 'http://') + ENV['CANONICAL_HOST']
    end
    def get_id(id, type)
        type + '-' + id
    end

    def id_to_key(id)
        id.slice(2, id.length - 1)
    end

    def respond_forbidden
        render json: {exception: "Not authorized"}, root: false, status: 403
    end

    def name_to_url(name)
        name.downcase.gsub(/[^a-z0-9\-_]+/, '-').gsub(/-+/, '-')
    end

end