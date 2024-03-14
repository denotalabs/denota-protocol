import axios from "axios";

const METADATA_SERVICE = "https://denota.klymr.me/nft-lighthouse";  // TODO update to new URL

interface NotaMetadata {
  desc?: string;
  tags?: string;
}

export async function uploadMetadata(
  file?: File,
  note?: string,
  tags?: string
) {
  if (!file && !note && !tags) {
    return { ipfsHash: undefined, imageURI: undefined };
  }

  const config = {
    headers: {
      "Content-Type": "multipart/form-data",
    },
  };

  const notaFormValues = new FormData();

  if (file) {
    notaFormValues.append("file", file);
  }

  if (note || tags) {
    const rqData: NotaMetadata = {};

    if (note) {
      rqData.desc = note;
    }

    if (tags) {
      rqData.tags = tags;
    }

    const json = JSON.stringify(rqData);
    const blob = new Blob([json], {
      type: "application/json",
    });
    notaFormValues.append("document", blob);
  }

  try {
    const resp = await axios.post(METADATA_SERVICE, notaFormValues, config);
    console.log(resp.data);
    return {
      ipfsHash: resp.data.key as string,
      imageURI: resp.data.imageURI as string,
    };
  } catch (error) {
    console.log(error);
    return { ipfsHash: undefined, imageURI: undefined };
  }
}
