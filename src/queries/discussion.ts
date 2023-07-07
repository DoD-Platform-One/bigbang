import { gql, GraphQLClient } from "graphql-request";

interface IGetDiscussionId {
    note: {
        discussion: {
            id: string
        }
    }
}

// graphql queries for discussion to find the discussion id from the given note id
export const getDiscussionId = async (noteId: string | number) => {

  const query = gql`
    query {
      note(id: "gid://gitlab/Note/${noteId}") {
        discussion {
          id
        }
      }
    }
  `;

  const endpoint = "https://repo1.dso.mil/api/graphql";
  const graphQLClient = new GraphQLClient(endpoint, {
    headers: {
      Authorization: `Bearer ${process.env.GITLAB_ACCESS_TOKEN}`,
    },
  });

  const data: IGetDiscussionId = await graphQLClient.request(query);
  return data.note.discussion.id.split("/").pop();
}; // function end bracket

